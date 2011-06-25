if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  require.paths.unshift('#{__dirname}/../examples')
  { Sequence } = require 'sequence'
  { Point2d, Point3d, triangulation,
    circumCircleCenter, inclusionInCircumCircle } = require 'delaunay'
else
  { Point2d, Point3d, triangulation,
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


describe "An empty triangulation", ->
  t = triangulation()

  it "should produce an empty sequence of triangles", ->
    expect(Sequence.empty t).toBe true

  it "should return anything on find", ->
    expect(t.find 1, 2, 3).toBe undefined

  it "should produce a non-empty triangulation when a triangle is added", ->
    expect(Sequence.empty t.plus 1, 2, 3).toBe false


describe "A triangulation with one triangle", ->
  t = triangulation([1,2,3])

  it "should not be empty", ->
    expect(Sequence.empty t).toBe false

  it "should have one triangle", ->
    expect(Sequence.size t).toBe 1

  it "should produce a sequence containing only the original triangle", ->
    expect(t.toSeq().toString()).toEqual "((1, 2, 3))"

  it "should return something when find is called with the original triangle", ->
    expect(t.find 1, 2, 3).toNotBe undefined

  it "should not change when we add the same triangle again", ->
    expect(t.plus 1, 2, 3).toEqual t

  it "should produce a triangulation of size two when we add a good triangle", ->
    expect(Sequence.size t.plus 1, 3, 4).toBe 2

  it "should throw an Exception when we add a bad triangle", ->
    expect(-> t.plus 1, 2, 4).toThrow 'Orientation mismatch.'
