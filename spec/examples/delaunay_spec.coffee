if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../examples')
  { Point2d, Point3d,
    circumCircleCenter, inclusionInCircumCircle } = require('delaunay')
else
  { Point2d, Point3d,
    circumCircleCenter, inclusionInCircumCircle } = pazy


describe "The triangle (1,4), (4,3), (-3,2)", ->
  a = new Point2d  1, 4
  b = new Point2d  4, 3
  c = new Point2d -3, 2

  it "should have (1,-1) as its center", ->
    expect(circumCircleCenter a, b, c).toEqual new Point2d 1, -1

  it "should have the origin inside", ->
    expect(inclusionInCircumCircle a, b, c, new Point2d 0, 0).toBeGreaterThan 0

  it "should have the point (3,3) inside", ->
    expect(inclusionInCircumCircle a, b, c, new Point2d 3, 3).toBeGreaterThan 0

  it "should have the point (6, -1) on it", ->
    expect(inclusionInCircumCircle a, b, c, new Point2d 6, -1).toBe 0

  it "should have the point (-3, -4) on it", ->
    expect(inclusionInCircumCircle a, b, c, new Point2d -3, -4).toBe 0

  it "should have the point (2,4) outside", ->
    expect(inclusionInCircumCircle a, b, c, new Point2d 2, 4).toBeLessThan 0

  it "should have the point (-10,10) outside", ->
    expect(inclusionInCircumCircle a, b, c, new Point2d -10, 10).toBeLessThan 0
