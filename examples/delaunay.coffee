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

  # The method `lift` computes the projection or _lift_ of this point onto the
  # standard parabola z = x * x + y * y.
  memo @, 'lift', -> new Point3d @x, @y, @x * @x + @y * @y

  equals: (p) -> @constructor == p?.constructor and @x == p.x and @y == p.y

  memo @, 'toString', -> "(#{@x}, #{@y})"
  memo @, 'hashCode', -> hashCode @toString()


# ----

# The class `Point2d` represents points in the x,y-plane and provides just the
# bare minimum of operations we need here.
class PointAtInfinity
  constructor: (@x, @y) ->
  isInfinite: -> true
  equals: (p) -> @constructor == p?.constructor and @x == p.x and @y == p.y

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

# The class `Triangle` represents an oriented triangle in the euclidean plane
# with no specified origin. In other words, the sequences `a, b, c`, `b, c, a`
# and `c, a,b` describe the same oriented triangle for given `a`, `b` and `c`,
# but `a, c, a` does not.
class Triangle
  constructor: (@a, @b, @c) ->

  memo @, 'vertices', ->
    if @a.toString() < @b.toString() and @a.toString() < @c.toString()
      [@a, @b, @c]
    else if @b.toString() < @c.toString()
      [@b, @c, @a]
    else
      [@c, @a, @b]

  # The method `liftedNormal` computes the downward-facing normal to the plane
  # formed by the lifts of this triangle's vertices.
  memo @, 'liftedNormal', ->
    n = @b.lift().minus(@a.lift()).cross @c.lift().minus(@a.lift())
    if n.z <= 0 then n else n.times -1

  # The method `circumCircleCenter` computes the center of the circum-circle
  # of this triangle.
  memo @, 'circumCircleCenter', ->
    n = @liftedNormal()
    new Point2d(n.x, n.y).times -0.5 / n.z if 1e-6 < Math.abs n.z

  # The method `circumCircleCenter` computes the center of the circum-circle
  # of this triangle.
  memo @, 'circumCircleRadius', ->
    c = @circumCircleCenter()
    square = (x) -> x * x
    Math.sqrt square(c.x - @a.x) + square(c.y - @a.y)

  # The function `inclusionInCircumCircle` checks whether a point d is inside,
  # outside or on the circle through this triangle's vertices. A positive
  # return value means inside, zero means on and a negative value means
  # outside.
  inclusionInCircumCircle: (d) -> @liftedNormal().dot d.lift().minus @a.lift()

  memo @, 'toSeq',    -> seq @vertices()
  memo @, 'toString', -> "T(#{seq.join @, ', '})"
  memo @, 'hashCode', -> hashCode @toString()

  equals: (other) -> seq.equals @, other


# ----

# The function `triangulation` creates an oriented triangulation in the
# euclidean plane. By _oriented_, we mean that the vertices of each triangle
# are assigned one out of two possible circular orders. Whenever two triangles
# share an edge, we moreover require the orientations of these to 'match' in
# such a way that the induced orders on the pair of vertices defining the edge
# are exactly opposite.
triangulation = do ->

  # The hidden class `Triangulation` implements our data structure.
  class Triangulation

    # The constructor takes a map specifying the associated third triangle
    # vertex for any oriented edge that is part of an oriented triangle.
    constructor: (@third__ = new HashMap()) ->

    # The method `toSeq` returns the triangles contained in the triangulation
    # as a lazy sequence.
    memo @, 'toSeq', ->
      seq.map(@third__, ([e, [t, c]]) -> t if equal c, t.a)?.select (x) -> x?

    # The method `third` finds the unique third vertex forming a triangle with
    # the two given ones in the given orientation, if any.
    third: (a, b) -> @third__.get([a, b])?[1]

    # The method `triangle` finds the unique oriented triangle with the two
    # given pair of vertices in the order, if any.
    triangle: (a, b) -> @third__.get([a, b])?[0]

    # The method `plus` returns a triangulation with the given triangle added
    # unless it is already present or creates an orientation mismatch. In the
    # first case, the original triangulation is returned without changes; in
    # the second, an exception is raised.
    plus: (a, b, c) ->
      if equal @third(a, b), c
        this
      else if seq.find([[a, b], [b, c], [c, a]], ([p, q]) => @third p, q)
        throw new Error "Orientation mismatch."
      else
        t = new Triangle a, b, c
        added = [[[a, b], [t, c]], [[b, c], [t, a]], [[c, a], [t, b]]]
        new Triangulation @third__.plusAll added

    # The method `minus` returns a triangulation with the given triangle
    # removed, if present.
    minus: (a, b, c) ->
      if not equal @third(a, b), c
        this
      else
        new Triangulation @third__.minusAll [[a, b], [b, c], [c, a]]

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
    outer = new Triangle new PointAtInfinity( 1,  0),
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

    # The method `triangle` finds the unique oriented triangle with the two
    # given pair of vertices in the order, if any.
    triangle: (a, b) -> @triangulation__.triangle a, b

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
        @triangle(a, b).inclusionInCircumCircle(d) > 0

    # The private function `subdivide` takes a triangulation `T`, a triangle
    # `t` and a site `p` inside that triangle and creates a new triangulation
    # in which `t` is divided into three new triangles with `p` as a common
    # vertex.
    subdivide = (T, t, p) ->
      trace -> "subdivide [#{T.triangulation__.toSeq().join ', '}], #{t}, #{p}"
      [a, b, c] = t.vertices()
      S = T.triangulation__.minus(a,b,c).plus(a,b,p).plus(b,c,p).plus(c,a,p)
      new T.constructor(
        S, T.sites__.plus(p),
        T.children__.plus([T.triangle(a,b),
          seq [S.triangle(a,b), S.triangle(b,c), S.triangle(c,a)]])
      )

    # The private function `flip` creates a new triangulation from `T` with the
    # edge defined by the indices `a` and `b` _flipped_. In other words, if the
    # edge `ab` lies in triangles `abc` and `bad`, then after the flip those
    # are replaced by new triangle `bcd` and `adc`.
    flip = (T, a, b) ->
      trace -> "flip [#{T.triangulation__.toSeq().join ', '}], #{a}, #{b}"
      c = T.third a, b
      d = T.third b, a
      S = T.triangulation__.minus(a,b,c).minus(b,a,d).plus(b,c,d).plus(a,d,c)
      children = seq [S.triangle(c, d), S.triangle(d, c)]
      new T.constructor(
        S, T.sites__,
        T.children__.plus([T.triangle(a,b), children],
                          [T.triangle(b,a), children])
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
exports.Triangle = Triangle
exports.Point2d = Point2d
exports.delaunayTriangulation = delaunayTriangulation

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
