class Point2d
  constructor: (@x, @y) ->
  projection: -> new Point3d @x, @y, @x * @x + @y * @y
  times: (f) -> new Point2d @x * f, @y * f

class Point3d
  constructor: (@x, @y, @z) ->
  minus: (p) -> new Point3d @x - p.x, @y - p.y, @z - p.z
  times: (f) -> new Point3d @x * f, @y * f, @z * f
  dot:   (p) -> @x * p.x + @y * p.y + @z * p.z
  cross: (p) -> new Point3d @y*p.z - @z*p.y, @z*p.x - @x*p.z, @x*p.y - @y*p.x


# This functions computes the center of the circum-circle of a given
# triangle, specified by three input points.
circumCircleCenter = (a, b, c) ->

  # First, the normal to the plane formed by the projections of the
  # points a, b and c onto a standard parabola is computed.
  ap = a.projection()
  n = b.projection().minus(ap).cross c.projection().minus(ap)

  # This normal scaled to z=-1/2 and projected back onto the x,y-plane
  # yields the desired point.
  if Math.abs(n.z) > 1e-6
    p = n.times 1 / (-0.5 * n.z)
    new Point2d p.x, p.y


# This function checks whether a point d is inside, outside or on the
# circle through points a, b and c. A positive return value means
# inside, zero means on and a negative value means outside.
inclusionInCircumCircle = (a, b, c, d) ->

  # First, the normal to the plane formed by the projections of the
  # points a, b and c onto a standard parabola is computed.
  ap = a.projection()
  n = b.projection().minus(ap).cross c.projection().minus(ap)

  # This dot product tells us whether the projection of d is on, below
  # or above the plane of the projected triangle, and thus whether d
  # is on, inside or outside the circum-circle of the original one.
  d.projection().minus(ap).dot(n) * (if n.z > 0 then -1 else 1)
