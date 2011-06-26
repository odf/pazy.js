# These are the beginnings of a package to compute 2-dimensional Delaunay
# triangulations via the incremental flip algorithm.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# First, we import some necessary data structures (**TODO**: use a better
# package system).
if typeof(require) != 'undefined'
  require.paths.unshift '#{__dirname}/../lib'
  { recur, resolve }   = require 'functional'
  { Sequence }         = require 'sequence'
  { HashSet, HashMap } = require 'indexed'
else
  { recur, resolve, Sequence, HashSet, HashMap } = this.pazy

# ----

# The class `Point2d` represents points in the x,y-plane and provides just the
# bare minimum of operations we need here.
class Point2d
  constructor: (@x, @y) ->
  plus:  (p) -> new Point2d @x + p.x, @y + p.y
  minus: (p) -> new Point2d @x + p.x, @y + p.y
  times: (f) -> new Point2d @x * f, @y * f


# ----

# The class `Point3d` represents points in 3-dimensional space and provides
# just the bare minimum of operations we need here.
class Point3d
  constructor: (@x, @y, @z) ->
  minus: (p) -> new Point3d @x - p.x, @y - p.y, @z - p.z
  times: (f) -> new Point3d @x * f, @y * f, @z * f
  dot:   (p) -> @x * p.x + @y * p.y + @z * p.z
  cross: (p) -> new Point3d @y*p.z - @z*p.y, @z*p.x - @x*p.z, @x*p.y - @y*p.x


# ----

# The function `lift` computes the projection or _lift_ of a given point in
# the plane onto the standard parabola z = x * x + y * y.
lift = (p) -> new Point3d p.x, p.y, p.x * p.x + p.y * p.y

# ----

# The function `unlift` projects a point in 3d space back onto the x,y-plane.
unlift = (p) -> new Point2d p.x, p.y

# ----

# The function `liftedNormal` computes the downward-facing normal to the plane
# formed by the lifts of its input points a, b and c.

liftedNormal = (a, b, c) ->
  n = lift(b).minus(lift(a)).cross lift(c).minus(lift(a))
  if n.z > 0 then n.times(-1) else n


# ----

# The function `circumCircleCenter` computes the center of the circum-circle
# of a given triangle, specified by three input points.
circumCircleCenter = (a, b, c) ->
  n = liftedNormal a, b, c
  unlift n.times -0.5 / n.z if Math.abs(n.z) > 1e-6


# ----

# The function `inclusionInCircumCircle` checks whether a point d is inside,
# outside or on the circle through points a, b and c. A positive return value
# means inside, zero means on and a negative value means outside.
inclusionInCircumCircle = (a, b, c, d) ->
  liftedNormal(a, b, c).dot lift(d).minus lift(a)


# ----

# The helper function `seq` creates a sequence from its argument
# list.
seq = (args...) -> new Sequence args


# ----

# The function `triangulation` creates an _oriented_ abstract triangulation,
# i.e. one in which the vertices of each triangle are assigned one out of two
# possible circular orders. Whenever two triangles share an edge, we moreover
# require the orientations of these to 'match' in such a way that the induced
# orders on the pair of vertices defining the edge are exactly opposite.
#
# The triangulation is abstract in the sense that we do not impose any
# restrictions on the objects representing vertices.
triangulation = do ->

  # The hidden class `Triangulation` implements our data structure.
  class Triangulation

    # The constructor takes a set of triangles and a map specifying the
    # associated third triangle vertex for any oriented edge that is part of
    # an oriented triangle.
    constructor: (@triangles__ = new HashSet(), @third__ = new HashMap()) ->

    # The method `toSeq` returns the triangles contained in the triangulation
    # as a lazy sequence.
    toSeq: -> @triangles__.toSeq()

    # The method `find` returns a canonical representation for the unique
    # triangle in this triangulation, if any, which contains the two or three
    # given vertices in the correct order.
    find: (a, b, c) ->
     if c?
        seq(seq(a, b, c), seq(b, c, a), seq(c, a, b)).
          find((t) => @triangles__.contains(t))
      else
        c = @third__.get seq a, b
        @find a, b, c if c?

    # The method `plus` returns a triangulation with the given triangle added
    # unless it is already present or creates an orientation mismatch. In the
    # first case, the original triangulation is returned without changes; in
    # the second, an exception is raised.
    plus: (a, b, c) ->
      if @find a, b, c
        this
      else if seq(seq(a, b), seq(b, c), seq(c, a)).find((e) => @third__.get(e)?)
        throw new Error 'Orientation mismatch.'
      else
        new Triangulation(
          @triangles__.plus(seq(a, b, c)),
          @third__.plusAll(seq [seq(a, b), c], [seq(b, c), a], [seq(c, a), b]))

    # The method `minus` returs a triangulation with the given triangle
    # removed, if present.
    minus: (a, b, c) ->
      t = @find a, b, c
      if t?
        new Triangulation(
          @triangles__.minus(t),
          @third__.minusAll(seq seq(a, b), seq(b, c), seq(c, a)))
      else
        this

  # Here we define our access point. The function `triangulation` takes a list
  # of triangles, each given as an array of three abstract vertices.
  (args...) -> Sequence.reduce args, new Triangulation(), (t, x) -> t.plus x...


# ----

# The function `delaunayTriangulation` creates the Delaunay triangulation of a
# set of sites in the x,y-plane using the so-called incremental flip method.
delaunayTriangulation = do ->

  # Again, we use a hidden class to encapsulate the implementation details.
  class Triangulation
    # The triangle `outer` is a virtual, 'infinitely large' triangle which is
    # added internally to avoid special boundary considerations within the
    # algorithm. To distinguish its vertices from vertices corresponding to
    # regular sites, we use negative indices.
    outer = seq -1, -2, -3

    # The constructor is called with implementation specific data for the new
    # instance, specifically:
    #
    # 1. The underlying abstract triangulation.
    # 2. A mapping from vertex numbers to sites (`Point2d` instances).
    # 3. The set of all sites present.
    # 4. The child relation of the history DAG which is used to locate which
    # triangle a new site is in.
    constructor: (args...) ->
      @triangulation__ = args[0] || triangulation(outer.into [])
      @position__      = args[1] || []
      @sites__         = args[2] || new HashSet()
      @children__      = args[3] || new HashMap().plus [outer, seq()]

    # The method `toSeq` returns the proper (non-virtual) triangles contained
    # in this triangulation as a lazy sequence. It does so by removing any
    # triangles from the underlying triangulation object which contain a
    # virtual vertex.
    toSeq: -> Sequence.select @triangulation__, (t) -> t.forall (n) -> n >= 0

    # The method `position` returns the coordinates corresponding to a given
    # vertex number as a `Point2d` instance.
    position: (n) -> @position__.get n

    # The method `isRightOf` determines which side of the oriented line given
    # by the sites with indices `a` and `b` the point `p` (a `Point2d`
    # instance) lies on. A positive value means it is to the right, a negative
    # value to the left, and a zero value on the line.
    isRightOf: (a, b, p) ->
      if a < 0 and b < 0
        0
      else if a < 0
        -@isRightOf b, a, p
      else
        r = @position__ a
        rs = switch b
             when -1 then new Point2d  1,  0
             when -2 then new Point2d -1,  1
             when -3 then new Point2d -1, -1
             else         @position__(b).minus r
        rp = p.minus r
        rs.x * rp.y - rs.y * rp.x

    # The method `isInTriangle` returns true if the given `Point2d` instance
    # `p` is contained in the triangle `t` given as a sequence of site
    # indices.
    isInTriangle: (t, p) ->
      [a, b, c] = t.into []
      seq([a, b], [b, c], [c, a]).forall (r, s) => @isRightOf(r, s, p) <= 0

    # The method `containingTriangle` returns the triangle the given point is
    # in.
    containingTriangle: (p) ->
      step = (t) =>
        if t?
          candidates = @children__.get t
          if Sequence.empty candidates
            t
          else
            recur => step candidates.find (s) => @isInTriangle s, p
      resolve step outer

    # The method `plus` creates a new Delaunay triangulation with the given
    # `Point2d` instance added as a site.
    plus: (p) ->
      if @sites__.contains p
        this
      else
        # ...

  # Here we define our access point. The function `delaunayTriangulation` takes
  # a list of sites, each given as a `Point2d` instance.
  (args...) -> Sequence.reduce args, new Triangulation(), (t, x) -> t.plus x

# ----

# We export the classes `Point2d` and `Point3d` and the functions
# `circumCircleCenter`, `inclusionInCircumCircle` and `triangulation` for
# testing.

exports ?= this.pazy ?= {}
exports.Point2d = Point2d
exports.Point3d = Point3d
exports.circumCircleCenter      = circumCircleCenter
exports.inclusionInCircumCircle = inclusionInCircumCircle
exports.triangulation           = triangulation
exports.delaunayTriangulation   = delaunayTriangulation
