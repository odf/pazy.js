# Computing Delaunay triangulations and stuff.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs

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

# The function `lift` computes the projection or 'lift' of a given
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
