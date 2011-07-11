if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require 'sequence'
  { HashSet }  = require 'indexed'
else
  { Sequence, HashSet } = pazy


class FunnyKey
  constructor: (@value) ->

  hashCode: -> @value % 256

  equals: (other) -> @value == other.value

  toString: -> "FunnyKey(#{@value})"

FunnyKey.sorter = (a, b) -> a.value - b.value


describe "A HashSet", ->

	describe "with two items the first of which is removed", ->
    hash = new HashSet().plus('A').plus('B').minus('A')

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should not be the same object as another one constructed like it", ->
      expect(hash).not.toBe(new HashSet().plus('A').plus('B').minus('A'))


  describe "when empty", ->
    hash = new HashSet()

    it "should have size 0", ->
      expect(hash.size()).toEqual 0

    it "should be empty", ->
      expect(hash.size()).toBe 0

    it "should return false on contains", ->
      expect(hash.contains("first")).toBe false

    it "should still be empty when minus is called", ->
      expect(hash.minus("first").size()).toEqual 0

    it "should have length 0 as an array", ->
      expect(hash.toArray().length).toEqual 0

    it "should print as HashSet(EmptyNode)", ->
      expect(hash.toString()).toEqual('HashSet(EmptyNode)')


  describe "containing one item", ->
    hash = new HashSet().plus("first")

    it "should have size 1", ->
      expect(hash.size()).toEqual 1

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should be empty when the item is removed", ->
      expect(hash.minus("first").size()).toBe 0

    it "should be empty when the item is removed, twice", ->
      expect(hash.minus("first", "first").size()).toBe 0

    it "should return true for the key", ->
      expect(hash.contains("first")).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains("second")).toBe false

    it "should contain the key", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain("first")

    it "should print as HashSet(first)", ->
      expect(hash.toString()).toEqual('HashSet(first)')


  describe "containing one item with custom hashCode() and equals()", ->
    key = new FunnyKey(33)
    hash = new HashSet().plus(key)

    it "should have size 1", ->
      expect(hash.size()).toEqual 1

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should be empty when the item is removed", ->
      expect(hash.minus(key).size()).toBe 0

    it "should return true for the key", ->
      expect(hash.contains(key)).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains("second")).toBe false

    it "should contain the key", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain(key)

    it "should print as HashSet(FunnyKey(33))", ->
      expect(hash.toString()).toEqual('HashSet(FunnyKey(33))')


  describe "containing two items", ->
    hash = new HashSet().plus("first").plus("second")

    it "should have size 2", ->
      expect(hash.size()).toEqual 2

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should not be empty when the first item is removed", ->
      expect(hash.minus("first").size()).toBeGreaterThan 0

    it "should be empty when both items are removed", ->
      expect(hash.minus("second").minus("first").size()).toBe 0

    it "should return true for both keys", ->
      expect(hash.contains("first")).toBe true
      expect(hash.contains("second")).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains("third")).toBe false

    it "should contain the keys", ->
      a = hash.toArray()
      expect(a.length).toEqual 2
      expect(a).toContain("first")
      expect(a).toContain("second")


  describe "containing two arrays", ->
    hash = new HashSet().plus([1,2,3]).plus([4,5,6])

    it "should have size 2", ->
      expect(hash.size()).toEqual 2

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should not be empty when the first item is removed", ->
      expect(hash.minus([1,2,3]).size()).toBeGreaterThan 0

    it "should be empty when both items are removed", ->
      expect(hash.minus([1,2,3]).minus([4,5,6]).size()).toBe 0

    it "should return true for both keys", ->
      expect(hash.contains([1,2,3])).toBe true
      expect(hash.contains([4,5,6])).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains([7,8,9])).toBe false

    it "should contain the keys", ->
      a = hash.toArray()
      expect(a.length).toEqual 2
      expect(a).toContain([1,2,3])
      expect(a).toContain([4,5,6])


  describe "containing two number", ->
    hash = new HashSet().plus(0, 2)

    it "should have size 2", ->
      expect(hash.size()).toEqual 2

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should not be empty when the first item is removed", ->
      expect(hash.minus(0).size()).toBeGreaterThan 0

    it "should be empty when both items are removed", ->
      expect(hash.minus(0).minus(2).size()).toBe 0

    it "should return true for both keys", ->
      expect(hash.contains(0)).toBe true
      expect(hash.contains(2)).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains(1)).toBe false

    it "should contain the keys", ->
      a = hash.toArray()
      expect(a.length).toEqual 2
      expect(a).toContain(0)
      expect(a).toContain(2)


  describe "containing two items with a level 1 collision", ->
    key_a = new FunnyKey(1)
    key_b = new FunnyKey(33)
    hash = new HashSet().plus(key_a).plus(key_b)

    it "should not change when an item not included is removed", ->
      a = hash.minus(new FunnyKey(5)).toArray()
      expect(a.length).toEqual 2
      expect(a).toContain key_a
      expect(a).toContain key_b

    it "should return true for both keys", ->
      expect(hash.contains(key_a)).toBe true
      expect(hash.contains(key_b)).toBe true

    it "should not be empty when the first item is removed", ->
      expect(hash.minus(key_a).size()).toBeGreaterThan 0

    it "should have size 1 when the first item is removed", ->
      expect(hash.minus(key_a).size()).toEqual 1

    it "should be empty when both items are removed", ->
      expect(hash.minus(key_a).minus(key_b).size()).toBe 0


  describe "containing three items with identical hash values", ->
    key_a = new FunnyKey(257)
    key_b = new FunnyKey(513)
    key_c = new FunnyKey(769)
    hash = new HashSet().plus(key_a).plus(key_b).plus(key_c)

    it "should contain the remaining two items when one is removed", ->
      a = hash.minus(key_a).toArray()
      expect(a.length).toEqual 2
      expect(a).toContain key_b
      expect(a).toContain key_c

    it "should contain four items when one with a new hash value is added", ->
      key_d = new FunnyKey(33)
      a = hash.plus(key_d).toArray()
      expect(a.length).toEqual 4
      expect(a).toContain key_a
      expect(a).toContain key_b
      expect(a).toContain key_c
      expect(a).toContain key_d

  describe "containing a wild mix of items", ->
    keys = (new FunnyKey(x * 5 + 7) for x in [0..16])
    hash = (new HashSet()).plus keys...

    it "should have the right number of items", ->
      expect(hash.size()).toEqual keys.length

    it "should return true for each key", ->
      expect(hash.contains(key)).toBe true for key in keys


  describe "containing lots of items", ->
    keys = (new FunnyKey(x) for x in [0..300])
    hash = (new HashSet()).plus keys...

    it "should have the correct number of keys", ->
      expect(hash.size()).toEqual keys.length

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should return true for each key", ->
      expect(hash.contains(key)).toBe true for key in keys

    it "should return false when fed another key", ->
      expect(hash.contains("third")).toBe false

    it "should contain all the keys when converted to an array", ->
      expect(hash.toArray().sort(FunnyKey.sorter)).toEqual(keys)

    it "should return an element sequence of the correct size", ->
      expect(hash.toSeq().size()).toEqual(hash.size())

    it "should return a sequence with all the keys on calling toSeq()", ->
      expect(hash.toSeq().into([]).sort(FunnyKey.sorter)).toEqual(keys)

    describe "some of which are then removed", ->
      ex_keys = keys[0..100]
      h = hash.minus ex_keys...

      it "should have the correct size", ->
        expect(h.size()).toEqual keys.length - ex_keys.length

      it "should not be the same as the original hash", ->
        expect(h).not.toEqual hash

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

      it "should return true for the remaining keys", ->
        expect(h.contains(key)).toBe true for key in keys when key not in ex_keys

      it "should return false for the removed keys", ->
        expect(h.contains(key)).toBe false for key in ex_keys

      it "should have exactly the remaining elements when made an array", ->
        expect(h.toArray().sort(FunnyKey.sorter)).toEqual(keys[101..])

    describe "from which some keys not included are removed", ->
      ex_keys = (new FunnyKey(x) for x in [1000..1100])
      h = hash.minus ex_keys...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the correct size", ->
        expect(h.size()).toEqual hash.size()

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

    describe "all of which are then removed", ->
      h = hash.minus keys...

      it "should have size 0", ->
        expect(h.size()).toEqual 0

      it "should be empty", ->
        expect(h.size()).toBe 0

      it "should return false for the removed keys", ->
        expect(h.contains(key)).toBe false for key in keys

      it "should convert to an empty array", ->
        expect(h.toArray().length).toBe 0

    describe "some of which are then inserted again", ->
      ex_keys = keys[0..100]
      h = hash.plus ex_keys...

      it "should be the same object as before", ->
         expect(h).toBe hash

      it "should have the same size as before", ->
        expect(h.size()).toEqual hash.size()

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

  describe "with a peculiar sequence of additions and deletions", ->
    class Triangle
      constructor: (@a, @b, @c) ->
      toSeq: -> new Sequence [@a, @b, @c]
      toString: -> "T(#{@a}, #{@b}, #{@c})"

    moves = [
      ['plus',0,1,13]
      ['plus',0,7,2]
      ['plus',0,13,14]
      ['plus',0,14,7]
      ['plus',1,6,13]
      ['plus',2,4,15]
      ['plus',2,7,15]
      ['plus',2,10,4]
      ['plus',2,15,12]
      ['minus',0,7,2]
      ['minus',2,4,15]
      ['minus',2,7,15]
    ]

    T = Sequence.reduce moves, new HashSet(), (s, [mode, a, b, c]) ->
      t = new Triangle a, b, c
      if mode == 'minus' then s.minus t else s.plus t

    it "should contain the correct number of items", ->
      expect(Sequence.size T).toBe 6

    it "should contain the correct number after one item is removed", ->
      expect(Sequence.size T.minus new Triangle 2, 10, 4).toBe 5
