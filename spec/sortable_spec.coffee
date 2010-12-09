if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  Sortable = require('sortable').Sortable
else
  Sortable = pazy.Sortable


describe "A Sortable with the numbers 3, 4, 2, 5, 1, 7 and 6 added", ->
  sortable = new Sortable((a, b) -> a < b).plus(3, 4, 2, 5, 1, 7, 6)

  it "should have size 7", ->
    expect(sortable.size()).toBe 7

  it "should return the numbers from 1 to 7 on a call to sort()", ->
    expect(sortable.sort()).toEqual [1 .. 7]

  describe "to which the numbers 9, 0 and 8 are added", ->
    s = sortable.plus(9, 0, 8)

    it "should have size 10", ->
      expect(s.size()).toBe 10

    it "should return the numbers from 0 to 9 on a call to sort()", ->
      expect(s.sort()).toEqual [0 .. 9]

  describe "to which the numbers 0, 3 and 5 are added", ->
    s = sortable.plus(0, 3, 5)

    it "should have size 10", ->
      expect(s.size()).toBe 10

    it "should return the numbers from 0,1,2,3,3,4,5,5,6,7 on sort()", ->
      expect(s.sort()).toEqual [0, 1, 2, 3, 3, 4, 5, 5, 6, 7]
