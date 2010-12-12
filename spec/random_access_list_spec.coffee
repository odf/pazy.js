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

  it "should have 9-i at position i for i = 0..9", ->
    expect(list.lookup(i)).toBe 9-i for i in [0..9]

  it "should have nothing at position 10", ->
    expect(list.lookup(10)).toBe undefined

  it "should not allow updating at position 10", ->
    expect(-> list.update(10, "ten")).toThrow "index too large"

  it "should not allow updating at position -1", ->
    expect(-> list.update(-1, "ten")).toThrow "negative index"

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

    it "should have 7-i at position i for i = 0..7", ->
      expect(test.lookup(i)).toBe 7-i for i in [0..7]

    it "should have nothing at position 8", ->
      expect(test.lookup(8)).toBe undefined

    it "should have nothing at position 10", ->
      expect(test.lookup(10)).toBe undefined

  describe "of which the entry at position 4 is replaced", ->
    test = list.update(4, "five")

    it "should have size 10", ->
      expect(test.size()).toBe 10

    it "should start with a 9", ->
      expect(test.first()).toBe 9

    it "should end with a 0", ->
      t = test
      t = t.rest() while t.rest()?.first()?
      expect(t.first()).toBe 0

    it "should have the original values everywhere else", ->
      expect(test.lookup(i)).toBe 9-i for i in [0..9] when i != 4

    it "should have 5 at position 4", ->
      expect(test.lookup(4)).toBe 'five'

    it "should have nothing at position 10", ->
      expect(test.lookup(10)).toBe undefined
