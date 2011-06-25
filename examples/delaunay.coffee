# Computing Delaunay triangulations and stuff.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# First, we import some necessary data structures (**TODO**: use a
# better package system).
if typeof(require) != 'undefined'
  require.paths.unshift '#{__dirname}/../lib'
  { HashSet, HashMap } = require 'indexed'
  { Sequence } = require 'sequence'
else
  { HashSet, HashMap, Sequence } = this.pazy

# ----

# The class `Point2d` represents points in the x,y-plane and provides
# just the bare minimum of operations we need here.
class Point2d
  constructor: (@x, @y) ->
  times: (f) -> new Point2d @x * f, @y * f


# ----

# The class `Point3d` represents points in 3-dimensional space and
# provides just the bare minimum of operations we need here.
class Point3d
  constructor: (@x, @y, @z) ->
  minus: (p) -> new Point3d @x - p.x, @y - p.y, @z - p.z
  times: (f) -> new Point3d @x * f, @y * f, @z * f
  dot:   (p) -> @x * p.x + @y * p.y + @z * p.z
  cross: (p) -> new Point3d @y*p.z - @z*p.y, @z*p.x - @x*p.z, @x*p.y - @y*p.x


# ----

# The function `lift` computes the projection or _lift_ of a given
# point in the plane onto the standard parabola z = x * x + y * y.
lift = (p) -> new Point3d p.x, p.y, p.x * p.x + p.y * p.y

# ----

# The function `unlift` projects a point in 3d space back onto the
# x,y-plane.
unlift = (p) -> new Point2d p.x, p.y

# ----

# The function `liftedNormal` computes the downward-facing normal to
# the plane formed by the lifts of its input points a, b and c.

liftedNormal = (a, b, c) ->
  n = lift(b).minus(lift(a)).cross lift(c).minus(lift(a))
  if n.z > 0 then n.times(-1) else n


# ----

# The function `circumCircleCenter` computes the center of the
# circum-circle of a given triangle, specified by three input points.
circumCircleCenter = (a, b, c) ->

  # The lifted normal scaled to z=-1/2 and projected back onto the
  # x,y-plane yields the desired point.
  n = liftedNormal a, b, c
  unlift n.times -0.5 / n.z if Math.abs(n.z) > 1e-6


# ----

# The function `inclusionInCircumCircle` checks whether a point d is
# inside, outside or on the circle through points a, b and c. A
# positive return value means inside, zero means on and a negative
# value means outside.
inclusionInCircumCircle = (a, b, c, d) ->

  # Equivalently, we can ask whether the lift of d is below, on or
  # above the plane formed by the lifts of the points a, b and c,
  # which we can readily read of the dot product of the lifted normal
  # and the vector from the lift of a to the lift of d.
  liftedNormal(a, b, c).dot lift(d).minus lift(a)


# ----

# The function `Triangulation` creates an _oriented_ abstract
# triangulation, i.e. one in which the vertices of each triangle are
# assigned one out of two possible circular orders. Whenever two
# triangles share an edge, we moreover require the orientations of
# these to 'match' in such a way that the induced orders on the pair
# of vertices defining the edge are exactly opposite.
#
# The triangulation is abstract in the sense that we do not impose any
# restrictions on the objects representing vertices.
#
# Most of the implementation details are hidden within a closure via
# the `do ->` construct.

triangulation = do ->
  # The helper function `seq` creates a sequence from its argument
  # list.
  seq = (args...) -> new Sequence args

  # We use a hidden class to encapsulate the implementation details.
  class Triangulation

    # The constructor takes a set of triangles and a map specifying
    # the associated third triangle vertex for any oriented edge that
    # is part of an oriented triangle.
    constructor: (@triangles = new HashSet(), @third = new HashMap()) ->

    # The method `plus` returns a triangulation with the given
    # triangle added unless it is already present or creates an
    # orientation mismatch. In the first case, the original
    # triangulation is returned without changes; in the second, an
    # exception is raised.
    plus: (a, b, c) ->


    # For a given oriented triangle specified by its three vertices,
    # the method `find` returns a canonical vertex order if the
    # triangle is included in this triangulation or else `null`.
    find: (a, b, c) ->
      seq(seq(a, b, c), seq(b, c, a), seq(c, a, b)).find @triangles.contains

  # Here we define our access point. The function `triangulation`
  # takes a list of triangles, each given as an array of three
  # abstract vertices.
  (args...) -> Sequence.reduce args, new Triangulation(), (t, x) -> t.plus x...


# ----

# We export the classes `Point2d` and `Point3d` and the functions
# `circumCircleCenter` and `inclusionInCircumCircle` for testing.

exports ?= this.pazy ?= {}
exports.Point2d = Point2d
exports.Point3d = Point3d
exports.circumCircleCenter = circumCircleCenter
exports.inclusionInCircumCircle = inclusionInCircumCircle
