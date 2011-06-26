# These are the beginnings of a package to compute 2-dimensional Delaunay
# triangulations via the incremental flip algorithm.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# First, we import some necessary data structures (**TODO**: use a better
# package system).
if typeof(require) != 'undefined'
  require.paths.unshift '#{__dirname}/../lib'
  { HashSet, HashMap } = require 'indexed'
  { Sequence } = require 'sequence'
else
  { HashSet, HashMap, Sequence } = this.pazy

# ----

# The class `Point2d` represents points in the x,y-plane and provides just the
# bare minimum of operations we need here.
class Point2d
  constructor: (@x, @y) ->
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

  # The lifted normal scaled to z=-1/2 and projected back onto the x,y-plane
  # yields the desired point.
  n = liftedNormal a, b, c
  unlift n.times -0.5 / n.z if Math.abs(n.z) > 1e-6


# ----

# The function `inclusionInCircumCircle` checks whether a point d is inside,
# outside or on the circle through points a, b and c. A positive return value
# means inside, zero means on and a negative value means outside.
inclusionInCircumCircle = (a, b, c, d) ->

  # Equivalently, we can ask whether the lift of d is below, on or above the
  # plane formed by the lifts of the points a, b and c, which we can readily
  # read of the dot product of the lifted normal and the vector from the lift
  # of a to the lift of d.
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
      # If three vertices are given, we look for all three possible vertex
      # orders with the same orientation in the triangle list.
      if c?
        seq(seq(a, b, c), seq(b, c, a), seq(c, a, b)).
          find((t) => @triangles__.contains(t))
      # Otherwise we look for the corresponding third vertex, if any, and call
      # find again.
      else
        c = @third__.get seq a, b
        @find a, b, c if c?

    # The method `plus` returns a triangulation with the given triangle added
    # unless it is already present or creates an orientation mismatch. In the
    # first case, the original triangulation is returned without changes; in
    # the second, an exception is raised.
    plus: (a, b, c) ->
      # First, we check if the triangle was already there.
      if @find a, b, c
        this
      # Next, we make sure we don't create a duplicate oriented edge.
      else if seq(seq(a, b), seq(b, c), seq(c, a)).find((e) => @third__.get(e)?)
        throw new Error 'Orientation mismatch.'
      # If the given triangle is okay to add, we create a new instance.
      else
        new Triangulation(
          @triangles__.plus(seq(a, b, c)),
          @third__.plusAll(seq [seq(a, b), c], [seq(b, c), a], [seq(c, a), b]))

    # The method `minus` returs a triangulation with the given triangle
    # removed, if present.
    minus: (a, b, c) ->
      # First, we check if the given triangle is present.
      t = @find a, b, c
      # If so, we construct a new triangulation without it.
      if t?
        new Triangulation(
          @triangles__.minus(t),
          @third__.minusAll(seq seq(a, b), seq(b, c), seq(c, a)))
      # Otherwise, we just return this triangulation unchanged.
      else
        this

  # Here we define our access point. The function `triangulation` takes a list
  # of triangles, each given as an array of three abstract vertices.
  (args...) -> Sequence.reduce args, new Triangulation(), (t, x) -> t.plus x...


# ----

# The function `delaunayTriangulation` creates the Delaunay triangulation of a
# set of points in the x,y-plane using the so-called incremental flip method.
delaunayTriangulation = do ->

  # Again, we use a hidden class to encapsulate the implementation details.
  class Triangulation
    # The triangle `outer` is a virtual, 'infinitely large' triangle which is
    # added internally to avoid special boundary considerations within the
    # algorithm. To distinguish its (virtual) vertices from regular vertices,
    # we use negative numbers.
    outer = seq -1, -2, -3

    # The constructor arguments are specific to this particular
    # algorithm.
    constructor: (args...) ->
      # The underlying abstract triangulation:
      @triangulation__ = args[0] || triangulation(outer)
      # Maps vertex numbers to `Point2d` instances:
      @position__      = args[1] || new HashMap()
      # The set of all `Point2d` instances present:
      @points__        = args[2] || new HashSet()
      # Defines the history DAG used to locate which triangle a point is in:
      @children__      = args[3] || new HashMap().plus [outer, seq()]

    # The method `toSeq` returns the proper (non-virtual) triangles contained
    # in this triangulation as a lazy sequence. It does so by removing any
    # triangles from the underlying triangulation object which contain a
    # virtual vertex.
    toSeq: -> Sequence.select @triangulation__, (t) -> t.forall (n) -> n >= 0

    # The method `position` returns the coordinates corresponding to a given
    # vertex number as a `Point2d` instance.
    position: (n) -> @position__.get n


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
