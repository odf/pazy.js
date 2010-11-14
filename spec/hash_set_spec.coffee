require.paths.unshift './lib'

HashSet = require('hash_set').HashSet

class FunnyKey
  constructor: (@value) ->

  hashCode: -> @value % 256

  equals: (other) -> @value == other.value

  toString: -> "FunnyKey(#{@value})"


describe "A Hash", ->

	describe "with two items the first of which is removed", ->
    hash = new HashSet().plus('A').plus('B').minus('A')

    it "should not be empty", ->
      expect(hash.isEmpty).toEqual false


  describe "when empty", ->
    hash = new HashSet()

    it "should have size 0", ->
      expect(hash.size).toEqual 0

    it "should be empty", ->
      expect(hash.isEmpty).toEqual true

    it "should return false on get", ->
      expect(hash.get("first")).toEqual false

    it "should still be empty when without is called", ->
      expect(hash.without("first").size).toEqual 0

    it "should have length 0 as an array", ->
      expect(hash.toArray().length).toEqual 0

    it "should print as HashSet(EmptyNode)", ->
      expect(hash.toString()).toEqual('HashSet(EmptyNode)')


  describe "containing one item", ->
    hash = new HashSet().with("first")

    it "should have size 1", ->
      expect(hash.size).toEqual 1

    it "should not be empty", ->
      expect(hash.isEmpty).toEqual false

    it "should be empty when the item is removed", ->
      expect(hash.without("first").isEmpty).toEqual true

    it "should return true for the key", ->
      expect(hash.get("first")).toEqual true

    it "should return false when fed another key", ->
      expect(hash.get("second")).toEqual false

    it "should contain the key", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain("first")

    it "should print as HashSet(LeaveNode(first))", ->
      expect(hash.toString()).toEqual('HashSet(LeaveNode(first))')

  describe "containing two items with different hash values", ->
    key_a = new FunnyKey(1)
    key_b = new FunnyKey(33)
    hash = new HashSet().with(key_a).with(key_b)

    it "should not change when an item not included is removed", ->
      a = hash.without(new FunnyKey(5)).toArray()
      expect(a.length).toEqual 2
      expect(a).toContain key_a
      expect(a).toContain key_b

    it "should not be empty when the first item is removed", ->
      expect(hash.without(key_a).isEmpty).toEqual false

    it "should be empty when all items are removed", ->
      expect(hash.without(key_a).without(key_b).isEmpty).toEqual true
