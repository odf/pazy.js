if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { seq }       = require('sequence')
  { Partition } = require('partition')
else
  { seq, Partition } = pazy


describe "A partition with some unions applied", ->
  partition = seq.reduce([[1,2],[3,4],[5,6],[7,8],[2,3],[1,6]],
    new Partition(), (p, [x,y]) -> p.union x, y)

  it "should return 9 as the representative of 9", ->
    expect(partition.find 9).toBe 9

  seq.each [2..6], (n) ->
    it "should return the same representative for 1 and #{n}", ->
      expect(partition.find 1).toEqual partition.find n

  it "should return the same representative for 7 and 8", ->
    expect(partition.find 7).toEqual partition.find 8

  it "should return different representatives for 1 and 8", ->
    expect(partition.find 1).toNotEqual partition.find 8
