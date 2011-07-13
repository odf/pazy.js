if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  require.paths.unshift('#{__dirname}/../examples')
  { seq }                   = require 'sequence'
  { delaunayTriangulation } = require 'delaunay'
else
  { seq, delaunayTriangulation } = pazy

guard = (f) ->
  try
    f()
  catch ex
    console.log ex.message
    console.log "" + ex.stack
    throw ex

position = (t, i) -> p = t.position(i); [p.x, p.y]

checkEdges = (t) ->
  seq.each t, (triangle) ->
    [a, b, c] = triangle.vertices()
    seq.each [[a, b], [b, c], [c, a]], ([r, s]) ->
      if r <= s
        u = t.position r
        v = t.position s
        w = t.position(t.third r, s) or t.third r, s
        x = t.position(t.third s, r) or t.third s, r
        it "should fullfil the Delaunay condition for #{u},#{v},#{w},#{x})", ->
          expect(t.mustFlip r, s).toBe false


describe "An empty Delaunay triangulation", ->
  t = delaunayTriangulation()

  it "should produce an empty sequence of triangles", ->
    expect(seq.empty t).toBeTruthy()

  it "should report any point as in the virtual outer triangle", ->
    expect(t.containingTriangle(1, 1).vertices()).toEqual [-3,-1,-2]


describe "A Delaunay triangulation with one site", ->
  t = delaunayTriangulation([0, 0])

  it "should contain that site at position 0", ->
    expect(position t, 0).toEqual [0, 0]

  it "should contain no triangles", ->
    expect(seq.empty t).toBeTruthy()


describe "A Delaunay triangulation with three sites", ->
  [p, q, r] = [[0, 0], [1, 0], [1, 1]]
  t = delaunayTriangulation(p, q, r)

  it "should contain those sites at positions 0, 1 and 2", ->
    expect(position t, 0).toEqual p
    expect(position t, 1).toEqual q
    expect(position t, 2).toEqual r

  it "should contain one triangle", ->
    expect(seq.size t).toBe 1


describe "A Delaunay triangulation with four sites", ->
  [p, q, r, s] = [[0, 0], [1, 0], [1, 1], [0, 1]]
  t = delaunayTriangulation(p, q, r, s)

  it "should contain those sites at positions 0, 1, 2 and 3", ->
    expect(position t, 0).toEqual p
    expect(position t, 1).toEqual q
    expect(position t, 2).toEqual r
    expect(position t, 3).toEqual s

  it "should contain two triangles", ->
    expect(seq.size t).toBe 2

  checkEdges t


describe "A Delaunay triangulation with four sites", ->
  [p, q, r, s] = [[5, 3], [1, 7], [9, 5], [4, 9]]
  t = delaunayTriangulation(p, q, r, s)

  it "should contain those sites at positions 0, 1, 2 and 3", ->
    expect(position t, 0).toEqual p
    expect(position t, 1).toEqual q
    expect(position t, 2).toEqual r
    expect(position t, 3).toEqual s

  it "should contain two triangles", ->
    expect(seq.size t).toBe 2

  checkEdges t


describe "A Delaunay triangulation with four sites", ->
  [p, q, r, s] = [[5, 5], [9, 5], [2, 1], [3, 8]]
  t = delaunayTriangulation(p, q, r, s)

  it "should contain those sites at positions 0, 1, 2 and 3", ->
    expect(position t, 0).toEqual p
    expect(position t, 1).toEqual q
    expect(position t, 2).toEqual r
    expect(position t, 3).toEqual s

  it "should contain three triangles", ->
    expect(seq.size t).toBe 3

  checkEdges t


describe "A Delaunay triangulation with many sites", ->
  sites = [
    [70, 80], [ 6, 91], [91, 92], [33,  5], [67,  3], [32, 11], [ 5, 83],
    [65, 37], [33,  2], [ 5, 49], [66, 31], [62, 34], [93, 98], [28, 66],
    [39, 54], [97, 87], [16, 81]
  ]

  t = guard -> delaunayTriangulation sites...

  it "should contain triangles", ->
    expect(seq.size t).toBeGreaterThan 0

  checkEdges t


describe "A Delaunay triangulation with random sites", ->
  t = guard ->
    rnd = -> Math.floor(Math.random() * 100)
    seq.range(1, 500).reduce delaunayTriangulation(),  (s, i) ->
      s.plus rnd(), rnd()

  it "should have triangles", ->
    expect(seq.size t).toBeGreaterThan 0

  checkEdges t
