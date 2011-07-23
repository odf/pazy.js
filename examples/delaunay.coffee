# These are the beginnings of a package to compute 2-dimensional Delaunay
# triangulations via the incremental flip algorithm.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# First, we import some necessary data structures (**TODO**: use a better
# package system).
if typeof(require) != 'undefined'
  require.paths.unshift '#{__dirname}/../lib'
  { equal, hashCode }          = require 'core_extensions'
  { recur, resolve }           = require 'functional'
  { seq }                      = require 'sequence'
  { IntMap, HashSet, HashMap } = require 'indexed'
  { Queue }                    = require 'queue'
else
  { equal, hashCode, recur, resolve,
    seq, IntMap, HashSet, HashMap, Queue } = this.pazy

# ----

# Here's a quick hack for switching traces on and off.

trace = (s) -> #console.log s()


# ----

# A method to be used in class bodies in order to create a method with a
# memoized result.

memo = (klass, name, f) ->
  klass::[name] = -> x = f.call(this); (@[name] = -> x)()

# ----

# The class `Point2d` represents points in the x,y-plane and provides just the
# bare minimum of operations we need here.
class Point2d
  constructor: (@x, @y) ->
  isInfinite: -> false
  plus:  (p)  -> new Point2d @x + p.x, @y + p.y
  minus: (p)  -> new Point2d @x - p.x, @y - p.y
  times: (f)  -> new Point2d @x * f, @y * f
  equals: (p) -> @constructor == p.constructor and @x == p.x and @y == p.y

  memo @, 'toString', -> "(#{@x}, #{@y})"
  memo @, 'hashCode', -> hashCode @toString()


# ----

# The class `Point2d` represents points in the x,y-plane and provides just the
# bare minimum of operations we need here.
class PointAtInfinity
  constructor: (@x, @y) ->
  isInfinite: -> true
  equals: (p) -> @constructor == p.constructor and @x == p.x and @y == p.y

  memo @, 'toString', -> "inf(#{@x}, #{@y})"
  memo @, 'hashCode', -> hashCode @toString()


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

# The class `Triangle` represents an oriented, abstract triangle with no
# specified origin. In other words, the sequences `a, b, c`, `b, c, a` and `c,
# a,b` describe the same oriented triangle for given `a`, `b` and `c`, but `a,
# c, a` does not.
class Triangle
  constructor: (a, b, c) ->
    [as, bs, cs] = seq.map([a, b, c], (x) -> x.toString()).into []
    [@a, @b, @c] =
      if as < bs and as < cs
        [a, b, c]
      else if bs < cs
        [b, c, a]
      else
        [c, a, b]

  memo @, 'vertices', -> [@a, @b, @c]
  memo @, 'toSeq',    -> seq @vertices()
  memo @, 'toString', -> "T(#{@a}, #{@b}, #{@c})"
  memo @, 'hashCode', -> hashCode @toString()

  equals: (other) ->
    equal(@a, other.a) and equal(@b, other.b) and equal(@c, other.c)


# Here's a quick shortcut for the constructor.
tri = (a, b, c) -> new Triangle a, b, c

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
    constructor: (args...) ->
      @triangles__ = args[0] or new HashSet()
      @third__     = args[1] or new HashMap()

    # The method `toSeq` returns the triangles contained in the triangulation
    # as a lazy sequence.
    memo @, 'toSeq', -> @triangles__.toSeq()

    # The method `third` finds the unique third vertex forming a triangle with
    # the two given ones in the given orientation, if any.
    third: (a, b) -> @third__.get [a, b]

    # The method `find` returns a canonical representation for the unique
    # triangle in this triangulation, if any, which contains the two or three
    # given vertices in the correct order.
    find: (a, b, c) ->
      t = tri a, b, if c? then c else @third a, b
      t if @triangles__.contains t

    # The method `plus` returns a triangulation with the given triangle added
    # unless it is already present or creates an orientation mismatch. In the
    # first case, the original triangulation is returned without changes; in
    # the second, an exception is raised.
    plus: (a, b, c) ->
      if @find a, b, c
        this
      else if x = seq([[a, b], [b, c], [c, a]]).find((e) => @third__.get(e)?]
        [f, g] = x
        h = @third__.get x
        trace -> "  Error in plus [#{@toSeq()?.join ', '}], (#{a}, #{b}, #{c})"
        throw new Error "Orientation mismatch."
      else
        triangles = @triangles__.plus tri a, b, c
        third = @third__.plusAll seq [[[a, b], c], [[b, c], a], [[c, a], b]]
        new Triangulation triangles, third

    # The method `minus` returns a triangulation with the given triangle
    # removed, if present.
    minus: (a, b, c) ->
      t = @find a, b, c
      if t?
        triangles = @triangles__.minus t
        third = @third__.minusAll seq [[a, b], [b, c], [c, a]]
        new Triangulation triangles, third
      else
        this

  # Here we define our access point. The function `triangulation` takes a list
  # of triangles, each given as an array of three abstract vertices.
  (args...) -> seq.reduce args, new Triangulation(), (t, x) -> t.plus x...


# ----

# The function `delaunayTriangulation` creates the Delaunay triangulation of a
# set of sites in the x,y-plane using the so-called incremental flip method.
delaunayTriangulation = do ->

  # Again, we use a hidden class to encapsulate the implementation details.
  class Triangulation
    # The triangle `outer` is a virtual, 'infinitely large' triangle which is
    # added internally to avoid special boundary considerations within the
    # algorithm.
    outer = tri new PointAtInfinity( 1,  0),
                new PointAtInfinity(-1,  1),
                new PointAtInfinity(-1, -1)

    # The constructor is called with implementation specific data for the new
    # instance, specifically:
    #
    # 1. The underlying abstract triangulation.
    # 2. The set of all sites present.
    # 3. The child relation of the history DAG which is used to locate which
    # triangle a new site is in.
    constructor: (args...) ->
      @triangulation__ = args[0] || triangulation(outer.vertices())
      @sites__         = args[1] || new HashSet()
      @children__      = args[2] || new HashMap()

    # The method `toSeq` returns the proper (non-virtual) triangles contained
    # in this triangulation as a lazy sequence. It does so by removing any
    # triangles from the underlying triangulation object which contain a
    # virtual vertex.
    memo @, 'toSeq', -> seq.select @triangulation__, (t) ->
      seq.forall t, (p) -> not p.isInfinite()

    # The method `third` finds the unique third vertex forming a triangle with
    # the two given ones in the given orientation, if any.
    third: (a, b) -> @triangulation__.third a, b

    # The method `find` returns a canonical representation for the unique
    # triangle in this triangulation, if any, which contains the two or three
    # given vertices in the correct order.
    find: (a, b, c) -> @triangulation__.find a, b, c

    # The method `sideOf` determines which side of the oriented line given by
    # the sites with indices `a` and `b` the point `p` (a `Point2d` instance)
    # lies on. A positive value means it is to the right, a negative value to
    # the left, and a zero value on the line.
    sideOf: (a, b, p) ->
      if a.isInfinite() and b.isInfinite()
        -1
      else if a.isInfinite()
        - @sideOf b, a, p
      else
        ab = if b.isInfinite() then new Point2d b.x, b.y else b.minus a
        ap = p.minus a
        ap.x * ab.y - ap.y * ab.x

    # The method `isInTriangle` returns true if the given `Point2d` instance
    # `p` is contained in the triangle `t` given as a sequence of site
    # indices.
    isInTriangle: (t, p) ->
      [a, b, c] = t.vertices()
      seq([[a, b], [b, c], [c, a]]).forall ([r, s]) => @sideOf(r, s, p) <= 0

    # The method `containingTriangle` returns the triangle the given point is
    # in.
    containingTriangle: (p) ->
      step = (t) =>
        candidates = @children__.get t
        if seq.empty candidates
          t
        else
          recur => step candidates.find (s) => @isInTriangle s, p
      resolve step outer

    # The method `mustFlip` determines whether the triangles adjacent to the
    # given edge from `a` to `b` violates the Delaunay condition, in which case
    # it must be flipped.
    #
    # Some special considerations are necessary in the case that virtual
    # vertices are involved.
    mustFlip: (a, b) ->
      c = @third a, b
      d = @third b, a

      if (a.isInfinite() and b.isInfinite()) or not c? or not d?
        false
      else if a.isInfinite()
        @sideOf(d, c, b) > 0
      else if b.isInfinite()
        @sideOf(c, d, a) > 0
      else if c.isInfinite() or d.isInfinite()
        false
      else
        inclusionInCircumCircle(a, b, c, d) > 0

    # The private function `subdivide` takes a triangulation `T`, a triangle
    # `t` and a site `p` inside that triangle and creates a new triangulation
    # in which `t` is divided into three new triangles with `p` as a common
    # vertex.
    subdivide = (T, t, p) ->
      trace -> "subdivide [#{T.triangulation__.toSeq().join ', '}], #{t}, #{p}"
      [a, b, c] = t.vertices()
      new T.constructor(
        T.triangulation__.minus(a,b,c).plus(a,b,p).plus(b,c,p).plus(c,a,p),
        T.sites__.plus(p),
        T.children__.plus([T.find(a,b,c),
                           seq [tri(a,b,p), tri(b,c,p), tri(c,a,p)]])
      )

    # The private function `flip` creates a new triangulation from `T` with the
    # edge defined by the indices `a` and `b` _flipped_. In other words, if the
    # edge `ab` lies in triangles `abc` and `bad`, then after the flip those
    # are replaced by new triangle `bcd` and `adc`.
    flip = (T, a, b) ->
      trace -> "flip [#{T.triangulation__.toSeq().join ', '}], #{a}, #{b}"
      c = T.third a, b
      d = T.third b, a
      children = seq [tri(b, c, d), tri(a, d, c)]
      new T.constructor(
        T.triangulation__.minus(a,b,c).minus(b,a,d).plus(b,c,d).plus(a,d,c),
        T.sites__,
        T.children__.plus([T.find(a,b,c), children], [T.find(b,a,d), children])
      )

    # The private function `doFlips` takes a triangulation and a stack of
    # edges. If the topmost edge on the stack needs to be flipped, the function
    # calls itself recursively with the resulting triangulation and a stack in
    # which that edge is replaced by the two remaining edges of the opposite
    # triangle.
    doFlips = (T, stack) ->
      if seq.empty stack
        T
      else
        [a, b] = stack.first()
        if T.mustFlip a, b
          c = T.third a, b
          recur -> doFlips flip(T, a, b), seq([[a,c], [c,b]]).concat stack.rest()
        else
          recur -> doFlips T, stack.rest()

    # The method `plus` creates a new Delaunay triangulation with the given
    # (x, y) location added as a site.
    plus: (x, y) ->
      p = new Point2d x, y
      if @sites__.contains p
        this
      else
        t = @containingTriangle p
        [a, b, c] = t.vertices()
        seq([[b,a], [c,b], [a,c]]).reduce subdivide(this, t, p), (T, [u, v]) ->
          if T.sideOf(u, v, p) == 0
            w = T.third u, v
            if w?
              resolve doFlips flip(T, u, v), seq [[u, w], [w, v]]
            else
              T
          else
            resolve doFlips T, seq [[u, v]]

  # Here we define our access point. The function `delaunayTriangulation` takes
  # a list of sites, each given as a `Point2d` instance.
  (args...) -> seq.reduce args, new Triangulation(), (t, x) -> t.plus x...

# ----

# Exporting.

exports ?= this.pazy ?= {}
exports.Point2d = Point2d
exports.delaunayTriangulation = delaunayTriangulation
exports.circumCircleCenter = circumCircleCenter

# ----

# Some testing.

test = (n = 100, m = 10) ->
  seq.range(1, n).each (i) ->
    console.log "Run #{i}"

    rnd = -> Math.floor(Math.random() * 100)
    t = seq.range(1, m).reduce delaunayTriangulation(),  (s, j) ->
      p = [rnd(), rnd()]
      try
        s.plus p...
      catch ex
        console.log seq.join s, ', '
        console.log p
        console.log ex.stacktrace
        throw "Oops!"

if module? and not module.parent
  args = seq.map(process.argv[2..], parseInt)?.into []
  test args...
