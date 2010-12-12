if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { List }              = require('list')
  { RandomAccessList }  = require('random_access_list')
else
  { List, RandomAccessList } = pazy


describe "A queue with the elements 0 to 9 back to front", ->
  list = List.range(0, 9).reduce(new RandomAccessList(), (q, x) -> q.cons(x))

  it "should have size 10", ->
    expect(list.size()).toBe 10

  it "should start with a 9", ->
    expect(list.first()).toBe 9

  it "should end with a 0", ->
    t = list
    t = t.rest() while t.rest()?.first()?
    expect(t.first()).toBe 0

  it "should have 9 at position 0", ->
    expect(list.lookup(0)).toBe 9

  it "should have 5 at position 4", ->
    expect(list.lookup(4)).toBe 5

  it "should have 0 at position 9", ->
    expect(list.lookup(9)).toBe 0

  it "should have nothing at position 10", ->
    expect(list.lookup(10)).toBe undefined

  describe "of which the first two entries are dropped", ->
    test = list.rest().rest()

    it "should have size 8", ->
      expect(test.size()).toBe 8

    it "should start with a 7", ->
      expect(test.first()).toBe 7

    it "should end with a 0", ->
      t = test
      t = t.rest() while t.rest()?.first()?
      expect(t.first()).toBe 0

    it "should have 7 at position 0", ->
      expect(test.lookup(0)).toBe 7

    it "should have 3 at position 4", ->
      expect(test.lookup(4)).toBe 3

    it "should have 0 at position 7", ->
      expect(test.lookup(7)).toBe 0

    it "should have nothing at position 8", ->
      expect(test.lookup(8)).toBe undefined

    it "should have nothing at position 10", ->
      expect(test.lookup(10)).toBe undefined
