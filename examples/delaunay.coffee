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

  # The three given points are first projected onto a paraboloid.
  [ap, bp, cp] = [a.projection(), b.projection(), c.projection()]

  # The normal to the projected triangle is computed next.
  n = bp.minus(ap).cross cp.minus(ap)

  # The normal scaled to z=-1/2 and projected back onto the x,y-plane
  # yields the desired point.
  if Math.abs(n.z) > 1e-6
    p = n.times 1 / (-0.5 * n.z)
    new Point2d p.x, p.y


# This function checks whether a point d is inside, outside or on the
# circle through points a, b and c. A positive return value means
# inside, zero means on and a negative value means outside.
inclusionInCircumCircle = (a, b, c, d) ->

  # The four given points are first projected onto a paraboloid.
  [ap, bp, cp, dp] =
    [a.projection(), b.projection(), c.projection(), d.projection()]

  # The normal to the triangle formed by the projection of a, b and c
  # is computed next.
  n = bp.minus(ap).cross cp.minus(ap)

  # The following tells us whether the projection of d is on, below or
  # above the plane of the projected triangle, and thus whether d
  # itself is on, inside or outside the circum-circle of the original
  # one.
  d.minus(a).dot(n) * (if n.z > 0 then -1 else 1)
