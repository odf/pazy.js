require.paths.unshift './lib'

require 'underscore'

HashMap = require('hash_map').HashMap

class FunnyKey
  constructor: (@value) ->

  hashCode: -> @value % 256

  equals: (other) -> @value == other.value

  toString: -> "FunnyKey(#{@value})"

FunnyKey.sorter = (a, b) -> a[1] - b[1]


describe "A Hash", ->

	describe "with two items the first of which is removed", ->
    hash = new HashMap().plus(['A', true]).plus(['B', true]).minus('A')

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should not be the same object as another one constructed like it", ->
      h = new HashMap().plus(['A', true]).plus(['B', true]).minus('A')
      expect(hash).not.toBe h


  describe "when empty", ->
    hash = new HashMap()

    it "should have size 0", ->
      expect(hash.size).toEqual 0

    it "should be empty", ->
      expect(hash.isEmpty).toBe true

    it "should not return anything on get", ->
      expect(hash.get("first")).not.toBeDefined()

    it "should still be empty when without is called", ->
      expect(hash.without("first").size).toEqual 0

    it "should have length 0 as an array", ->
      expect(hash.toArray().length).toEqual 0

    it "should print as HashMap(EmptyNode)", ->
      expect(hash.toString()).toEqual('HashMap(EmptyNode)')


  describe "containing one item", ->
    hash = new HashMap().with(["first", 1])

    it "should have size 1", ->
      expect(hash.size).toEqual 1

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should retrieve the associated value for the key", ->
      expect(hash.get("first")).toBe 1

    it "should not return anything when fed another key", ->
      expect(hash.get("second")).not.toBeDefined()

    it "should be empty when the item is removed", ->
      expect(hash.without("first").isEmpty).toBe true

    it "should contain the key-value pair", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain(["first", 1])

    it "should print as HashMap(LeaveNode(first, 1))", ->
      expect(hash.toString()).toEqual('HashMap(LeaveNode(first, 1))')

    describe "the value of which is then changed", ->
      h = hash.with(["first", "one"])

      it "should have size 1", ->
        expect(h.size).toBe 1

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should retrieve the associated value for the key", ->
        expect(h.get("first")).toBe "one"

      it "should not return anything when fed another key", ->
        expect(h.get("second")).not.toBeDefined()

      it "should contain the new key-value pair", ->
        a = h.toArray()
        expect(a.length).toEqual 1
        expect(a).toContain(["first", "one"])

  describe "containing two items with level one collision", ->
    key_a = new FunnyKey(1)
    key_b = new FunnyKey(33)
    key_c = new FunnyKey(5)
    hash = new HashMap().with([key_a, "a"]).with([key_b, "b"])

    it "should contain two elements", ->
      expect(hash.size).toBe 2

    it "should not return anything when get is called with a third key", ->
      expect(hash.get(key_c)).not.toBeDefined()

    it "should not change when an item not included is removed", ->
      a = hash.without(key_c).toArray()
      expect(a.length).toBe 2
      expect(a).toContain [key_a, "a"]
      expect(a).toContain [key_b, "b"]

    it "should not be empty when the first item is removed", ->
      h = hash.without(key_a)
      expect(h.size).toBe 1

    it "should be empty when all items are removed", ->
      h = hash.without(key_a).without(key_b)
      expect(h.isEmpty).toBe true

  describe "containing three items with identical hash values", ->
    key_a = new FunnyKey(257)
    key_b = new FunnyKey(513)
    key_c = new FunnyKey(769)
    key_d = new FunnyKey(33)
    hash = new HashMap().with([key_a, "a"], [key_b, "b"], [key_c, "c"])

    it "should contain the remaining two items when one is removed", ->
      a = hash.without(key_a).toArray()
      expect(a.length).toBe 2
      expect(a).toContain [key_b, "b"]
      expect(a).toContain [key_c, "c"]

    it "should contain four items when one with a new hash value is added", ->
      a = hash.with([key_d, "d"]).toArray()
      expect(a.length).toBe 4
      expect(a).toContain [key_a, "a"]
      expect(a).toContain [key_b, "b"]
      expect(a).toContain [key_c, "c"]
      expect(a).toContain [key_d, "d"]

  describe "containing a wild mix of items", ->
    keys  = new FunnyKey(x * 5 + 7) for x in [0..16]
    items = [key, key.value] for key in keys
    hash  = (new HashMap()).with items...

    it "should have the right number of items", ->
      expect(hash.size).toEqual keys.length

    it "should retrieve the associated value for each key", ->
      expect(hash.get(key)).toBe key.value for key in keys

    it "should contain all the items when converted to an array", ->
      expect(hash.toArray().sort(FunnyKey.sorter)).toEqual(items)

  describe "containing lots of items", ->
    keys  = new FunnyKey(x) for x in [0..300]
    items = [key, key.value] for key in keys
    hash  = (new HashMap()).with items...

    it "should have the correct number of items", ->
      expect(hash.size).toEqual keys.length

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should retrieve the associated value for each key", ->
      expect(hash.get(key)).toBe key.value for key in keys

    it "should not return anythin when fed another key", ->
      expect(hash.get("third")).not.toBeDefined()

    it "should contain all the items when converted to an array", ->
      expect(hash.toArray().sort(FunnyKey.sorter)).toEqual(items)
