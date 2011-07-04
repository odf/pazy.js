if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  require.paths.unshift('#{__dirname}/../examples')
  { Sequence } = require 'sequence'
  { Point2d, Point3d, triangulation, delaunayTriangulation,
    circumCircleCenter, inclusionInCircumCircle } = require 'delaunay'
else
  { Point2d, Point3d, triangulation, delaunayTriangulation,
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
    expect(Sequence.empty t).toBeTruthy()

  it "shouldn't return anything on find", ->
    expect(t.find 1, 2, 3).toBeUndefined()

  it "should produce a non-empty triangulation when a triangle is added", ->
    expect(Sequence.empty t.plus 1, 2, 3).toBeFalsy()

  it "should not change when minus() is called", ->
    expect(t.minus 1, 2, 3).toEqual t


describe "A triangulation with one triangle", ->
  t = triangulation([1, 2, 3])

  it "should produce a sequence containing only the original triangle", ->
    expect(t.toSeq().toString()).toEqual "(T(1, 2, 3))"

  it "should not be empty", ->
    expect(Sequence.empty t).toBeFalsy()

  it "should have one triangle", ->
    expect(Sequence.size t).toBe 1

  it "should find that triangle again", ->
    expect(t.find(1, 2, 3).vertices()).toEqual [1, 2, 3]

  it "should find that triangle with its vertices cyclically permuted", ->
    expect(t.find(2, 3, 1).vertices()).toEqual [1, 2, 3]
    expect(t.find(3, 1, 2).vertices()).toEqual [1, 2, 3]

  it "should not find the same triangle when the orientation is reversed", ->
    expect(t.find 1, 3, 2).toBeUndefined()
    expect(t.find 3, 2, 1).toBeUndefined()
    expect(t.find 2, 1, 3).toBeUndefined()

  it "should find the three edges included in that triangle", ->
    expect(t.find(1, 2).vertices()).toEqual [1, 2, 3]
    expect(t.find(2, 3).vertices()).toEqual [1, 2, 3]
    expect(t.find(3, 1).vertices()).toEqual [1, 2, 3]

  it "should not find the edges in that triangle with reversed orientation", ->
    expect(t.find 1, 3).toBeUndefined()
    expect(t.find 3, 2).toBeUndefined()
    expect(t.find 2, 1).toBeUndefined()

  it "should not find unrelated triangles or edges", ->
    expect(t.find 1, 2, 3.01).toBeUndefined()
    expect(t.find 'a', 'b').toBeUndefined()

  it "should not change when we add the same triangle again", ->
    expect(t.plus 1, 2, 3).toEqual t

  it "should produce a triangulation of size two when we add a good triangle", ->
    expect(Sequence.size t.plus 1, 3, 4).toBe 2

  it "should throw an Exception when we add a bad triangle", ->
    expect(-> t.plus 1, 2, 4).toThrow 'Orientation mismatch.'

  it "should be empty after removing that triangle", ->
    expect(Sequence.empty t.minus 1, 2, 3).toBeTruthy()
    expect(Sequence.empty t.minus 2, 3, 1).toBeTruthy()
    expect(Sequence.empty t.minus 3, 1, 2).toBeTruthy()

  it "should not change when we call minus with a different triangle", ->
    expect(t.minus 1, 2, 4).toEqual t

  it "should not change when we call minus with the same triangle reversed", ->
    expect(t.minus 3, 2, 1).toEqual t


describe "An empty Delaunay triangulation", ->
  t = delaunayTriangulation()

  it "should produce an empty sequence of triangles", ->
    expect(Sequence.empty t).toBeTruthy()

  it "should report any point as in the virtual outer triangle", ->
    expect(t.containingTriangle(new Point2d 1, 1).vertices()).toEqual [-3,-1,-2]

describe "A Delaunay triangulation with one site", ->
  p = new Point2d 0, 0
  t = delaunayTriangulation(p)

  it "should contain that site at position 0", ->
    expect(t.position 0).toEqual p

  it "should contain no triangles", ->
    expect(Sequence.empty t).toBeTruthy()

  it "should report any point as left of any virtual edge", ->
    q = new Point2d 1, 0
    expect(t.sideOf -1, -2, q).toBeLessThan 0

  it "should report the point (1,0) to the right of edge -3,0", ->
    q = new Point2d 1, 0
    expect(t.sideOf -3, 0, q).toBeGreaterThan 0

  it "should report a point in the correct triangle", ->
    q = new Point2d 1, 0.1
    expect(t.containingTriangle(q).vertices()).toEqual [-2, 0, -1]

describe "A Delaunay triangulation with three sites", ->
  [p, q, r] = [new Point2d(0, 0), new Point2d(1, 0), new Point2d(1, 1)]
  t = delaunayTriangulation(p, q, r)

  it "should contain those sites at positions 0, 1 and 2", ->
    expect(t.position 0).toEqual p
    expect(t.position 1).toEqual q
    expect(t.position 2).toEqual r

  it "should contain one triangle", ->
    expect(Sequence.size t).toBe 1

  it "should report points as on the correct sides of edges", ->
    x = new Point2d 0.5, 0.25
    expect(t.sideOf -1, -2, x).toBeLessThan 0
    expect(t.sideOf 1, -1, x).toBeLessThan 0
    expect(t.sideOf -2, 2, x).toBeGreaterThan 0
    expect(t.sideOf -2, 1, x).toBeGreaterThan 0

  it "should report a point inside the triangle correctly", ->
    x = new Point2d 0.5, 0.25
    expect(t.containingTriangle(x).vertices()).toEqual [0, 1, 2]

describe "A Delaunay triangulation with four sites", ->
  [p, q, r, s] =
    [new Point2d(0, 0), new Point2d(1, 0), new Point2d(1, 1), new Point2d(0, 1)]
  t = delaunayTriangulation(p, q, r, s)

  it "should contain those sites at positions 0, 1, 2 and 3", ->
    expect(t.position 0).toEqual p
    expect(t.position 1).toEqual q
    expect(t.position 2).toEqual r
    expect(t.position 3).toEqual s

  it "should contain two triangles", ->
    expect(Sequence.size t).toBe 2

  it "should report a point inside the correct triangles", ->
    a = new Point2d 0.75, 0.25
    b = new Point2d 0.25, 0.75
    expect(t.containingTriangle(a).vertices()).toEqual [0, 1, 2]
    expect(t.containingTriangle(b).vertices()).toEqual [0, 2, 3]

describe "A Delaunay triangulation with four sites", ->
  [p, q, r, s] =
    [new Point2d(5, 3), new Point2d(1, 7), new Point2d(9, 5), new Point2d(4, 9)]
  t = delaunayTriangulation(p, q, r, s)

  it "should contain those sites at positions 0, 1, 2 and 3", ->
    expect(t.position 0).toEqual p
    expect(t.position 1).toEqual q
    expect(t.position 2).toEqual r
    expect(t.position 3).toEqual s

  it "should contain two triangles", ->
    expect(Sequence.size t).toBe 2

  Sequence.each t, (triangle) ->
    [a, b, c] = triangle.vertices()
    Sequence.each [[a, b], [b, c], [c, a]], ([r, s]) ->
      if r <= s
        it "should fullfil the Delaunay condition for edge (#{r},#{s})", ->
          expect(t.mustFlip r, s).toBe false

describe "A Delaunay triangulation with random sites", ->
  rnd = -> Math.floor(Math.random() * 100)
  sites = (new Point2d(rnd(), rnd()) for i in [1..100])
  t = delaunayTriangulation sites...

  it "should have triangles", ->
    expect(Sequence.size t).toBeGreaterThan 0

  Sequence.each t, (triangle) ->
    [a, b, c] = triangle.vertices()
    Sequence.each [[a, b], [b, c], [c, a]], ([r, s]) ->
      if r <= s
        it "should fullfil the Delaunay condition for edge (#{r},#{s})", ->
          expect(t.mustFlip r, s).toBe false
