if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  HashSet = require('indexed').HashSet
else
  HashSet = pazy.HashSet


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

    it "should return true for the key", ->
      expect(hash.contains("first")).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains("second")).toBe false

    it "should contain the key", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain("first")

    it "should print as HashSet(LeafNode(first))", ->
      expect(hash.toString()).toEqual('HashSet(LeafNode(first))')


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

    it "should print as HashSet(LeafNode(FunnyKey(33)))", ->
      expect(hash.toString()).toEqual('HashSet(LeafNode(FunnyKey(33)))')


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

    it "should return an element stream of the correct size", ->
      expect(hash.elements().size()).toEqual(hash.size())

    it "should return a stream with all the keys on calling elements()", ->
      expect(hash.elements().toArray().sort(FunnyKey.sorter)).toEqual(keys)

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
        expect(h.contains(key)).toBe true for key in keys when not key in ex_keys

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
