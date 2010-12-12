if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { List }              = require('list')
  { RandomAccessList }  = require('random_access_list')
else
  { List, RandomAccessList } = pazy


describe "A queue with the elements 0 to 99 back to front", ->
  list = List.range(0, 99).reduce(new RandomAccessList(), (q, x) -> q.cons(x))

  it "should have size 100", ->
    expect(list.size()).toBe 100

  it "should start with a 99", ->
    expect(list.first()).toBe 99

  it "should end with a 0", ->
    t = list
    t = t.rest() while t.rest()?.first()?
    expect(t.first()).toBe 0

  it "should have 99-i at position i for i = 0..99", ->
    expect(list.lookup(i)).toBe 99-i for i in [0..99]

  it "should have nothing at position 100", ->
    expect(list.lookup(100)).toBe undefined

  it "should not allow updating at position 100", ->
    expect(-> list.update(100, "ten")).toThrow "index too large"

  it "should not allow updating at position -1", ->
    expect(-> list.update(-1, "ten")).toThrow "negative index"

  describe "of which the first two entries are dropped", ->
    test = list.rest().rest()

    it "should have size 98", ->
      expect(test.size()).toBe 98

    it "should start with a 97", ->
      expect(test.first()).toBe 97

    it "should end with a 0", ->
      t = test
      t = t.rest() while t.rest()?.first()?
      expect(t.first()).toBe 0

    it "should have 97-i at position i for i = 0..97", ->
      expect(test.lookup(i)).toBe 97-i for i in [0..97]

    it "should have nothing at position 98", ->
      expect(test.lookup(98)).toBe undefined

    it "should have nothing at position 10", ->
      expect(test.lookup(100)).toBe undefined

  describe "of which the entry at position 44 is replaced", ->
    test = list.update(44, "fiftyfive")

    it "should still have size 100", ->
      expect(test.size()).toBe 100

    it "should start with a 99", ->
      expect(test.first()).toBe 99

    it "should end with a 0", ->
      t = test
      t = t.rest() while t.rest()?.first()?
      expect(t.first()).toBe 0

    it "should have the original values everywhere else", ->
      expect(test.lookup(i)).toBe 99-i for i in [0..99] when i != 44

    it "should have the new value at position 44", ->
      expect(test.lookup(44)).toBe 'fiftyfive'

    it "should have nothing at position 100", ->
      expect(test.lookup(100)).toBe undefined
