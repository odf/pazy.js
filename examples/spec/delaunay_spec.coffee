if typeof(require) != 'undefined'
  { seq }                   = require 'sequence'
  { delaunayTriangulation } = require 'delaunay'
else
  { seq, delaunayTriangulation } = pazy

checkEdges = (t) ->
  seq.each t, (triangle) ->
    [a, b, c] = triangle.vertices()
    seq.each [[a, b], [b, c], [c, a]], ([u, v]) ->
      if u.toString() <= v.toString()
        w = t.third u, v
        x = t.third v, u
        it "should fullfil the Delaunay condition for #{u},#{v},#{w},#{x})", ->
          expect(t.mustFlip u, v).toBe false

describe "A Delaunay triangulation", ->
  describe "that is empty", ->
    t = delaunayTriangulation()

    it "should produce an empty sequence of triangles", ->
      expect(seq.empty t).toBeTruthy()


  describe "with one site", ->
    t = delaunayTriangulation([0, 0])

    it "should contain no triangles", ->
      expect(seq.empty t).toBeTruthy()


  describe "with three sites", ->
    [p, q, r] = [[0, 0], [1, 0], [1, 1]]
    t = delaunayTriangulation(p, q, r)

    it "should contain one triangle", ->
      expect(seq.size t).toBe 1


  describe "four sites", ->
    [p, q, r, s] = [[0, 0], [1, 0], [1, 1], [0, 1]]
    t = delaunayTriangulation(p, q, r, s)

    it "should contain two triangles", ->
      expect(seq.size t).toBe 2

    checkEdges t


  describe "with four sites", ->
    [p, q, r, s] = [[5, 3], [1, 7], [9, 5], [4, 9]]
    t = delaunayTriangulation(p, q, r, s)

    it "should contain two triangles", ->
      expect(seq.size t).toBe 2

    checkEdges t


  describe "with four sites", ->
    [p, q, r, s] = [[5, 5], [9, 5], [2, 1], [3, 8]]
    t = delaunayTriangulation(p, q, r, s)

    it "should contain three triangles", ->
      expect(seq.size t).toBe 3

    checkEdges t


  describe "with many sites", ->
    sites = [
      [70, 80], [ 6, 91], [91, 92], [33,  5], [67,  3], [32, 11], [ 5, 83],
      [65, 37], [33,  2], [ 5, 49], [66, 31], [62, 34], [93, 98], [28, 66],
      [39, 54], [97, 87], [16, 81]
    ]

    t = delaunayTriangulation sites...

    it "should contain triangles", ->
      expect(seq.size t).toBeGreaterThan 0

    checkEdges t


  describe "with many random sites", ->
    rnd = -> Math.floor(Math.random() * 100)
    sites = seq.range(1, 500).map -> [rnd(), rnd()]
    t = sites.reduce delaunayTriangulation(),  (s, p) -> s.plus p...

    it "should have triangles", ->
      expect(seq.size t).toBeGreaterThan 0

    checkEdges t
