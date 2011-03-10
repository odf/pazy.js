if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  HashMap = require('indexed').HashMap
else
  HashMap = pazy.HashMap


class FunnyKey
  constructor: (@value) ->

  hashCode: -> @value % 256

  equals: (other) -> @value == other.value

  toString: -> "FunnyKey(#{@value})"

FunnyKey.sorter = (a, b) -> a[0].value - b[0].value


describe "A HashMap", ->

	describe "with two items the first of which is removed", ->
    hash = new HashMap().plus(['A', true]).plus(['B', true]).minus('A')

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should not be the same object as another one constructed like it", ->
      h = new HashMap().plus(['A', true]).plus(['B', true]).minus('A')
      expect(hash).not.toBe h


  describe "when empty", ->
    hash = new HashMap()

    it "should have size 0", ->
      expect(hash.size()).toEqual 0

    it "should be empty", ->
      expect(hash.size()).toBe 0

    it "should not return anything on get", ->
      expect(hash.get("first")).not.toBeDefined()

    it "should still be empty when minus is called", ->
      expect(hash.minus("first").size()).toEqual 0

    it "should have length 0 as an array", ->
      expect(hash.toArray().length).toEqual 0

    it "should print as HashMap(EmptyNode)", ->
      expect(hash.toString()).toEqual('HashMap(EmptyNode)')


  describe "containing one item", ->
    hash = new HashMap().plus(["first", 1])

    it "should have size 1", ->
      expect(hash.size()).toEqual 1

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should retrieve the associated value for the key", ->
      expect(hash.get("first")).toBe 1

    it "should not return anything when fed another key", ->
      expect(hash.get("second")).not.toBeDefined()

    it "should be empty when the item is removed twice", ->
      expect(hash.minus("first", "first").size()).toBe 0

    it "should contain the key-value pair", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain(["first", 1])

    it "should print as HashMap(first ~> 1)", ->
      expect(hash.toString()).toEqual('HashMap(first ~> 1)')

    describe "the value of which is then changed", ->
      h = hash.plus(["first", "one"])

      it "should have size 1", ->
        expect(h.size()).toBe 1

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

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
    hash = new HashMap().plus([key_a, "a"]).plus([key_b, "b"])

    it "should contain two elements", ->
      expect(hash.size()).toBe 2

    it "should not return anything when get is called with a third key", ->
      expect(hash.get(key_c)).not.toBeDefined()

    it "should not change when an item not included is removed", ->
      a = hash.minus(key_c).toArray()
      expect(a.length).toBe 2
      expect(a).toContain [key_a, "a"]
      expect(a).toContain [key_b, "b"]

    it "should not be empty when the first item is removed", ->
      h = hash.minus(key_a)
      expect(h.size()).toBe 1

    it "should be empty when all items are removed", ->
      h = hash.minus(key_a).minus(key_b)
      expect(h.size()).toBe 0

  describe "containing three items with identical hash values", ->
    key_a = new FunnyKey(257)
    key_b = new FunnyKey(513)
    key_c = new FunnyKey(769)
    key_d = new FunnyKey(33)
    hash = new HashMap().plus([key_a, "a"], [key_b, "b"], [key_c, "c"])

    it "should contain the remaining two items when one is removed", ->
      a = hash.minus(key_a).toArray()
      expect(a.length).toBe 2
      expect(a).toContain [key_b, "b"]
      expect(a).toContain [key_c, "c"]

    it "should contain four items when one with a new hash value is added", ->
      a = hash.plus([key_d, "d"]).toArray()
      expect(a.length).toBe 4
      expect(a).toContain [key_a, "a"]
      expect(a).toContain [key_b, "b"]
      expect(a).toContain [key_c, "c"]
      expect(a).toContain [key_d, "d"]

  describe "containing a wild mix of items", ->
    keys  = (new FunnyKey(x * 5 + 7) for x in [0..16])
    items = ([key, key.value] for key in keys)
    hash  = (new HashMap()).plus items...

    it "should have the right number of items", ->
      expect(hash.size()).toEqual keys.length

    it "should retrieve the associated value for each key", ->
      expect(hash.get(key)).toBe key.value for key in keys

    it "should contain all the items when converted to an array", ->
      expect(hash.toArray().sort(FunnyKey.sorter)).toEqual(items)

  describe "containing lots of items", ->
    keys  = (new FunnyKey(x) for x in [0..300])
    items = ([key, key.value] for key in keys)
    hash  = (new HashMap()).plus items...

    it "should have the correct number of items", ->
      expect(hash.size()).toEqual keys.length

    it "should not be empty", ->
      expect(hash.size()).toBeGreaterThan 0

    it "should retrieve the associated value for each key", ->
      expect(hash.get(key)).toBe key.value for key in keys

    it "should not return anythin when fed another key", ->
      expect(hash.get("third")).not.toBeDefined()

    it "should contain all the items when converted to an array", ->
      expect(hash.toArray().sort(FunnyKey.sorter)).toEqual(items)

    it "should return an item sequence of the correct size", ->
      expect(hash.items().size()).toEqual(hash.size())

    it "should return a sequence with all the keys on calling items()", ->
      expect(hash.items().into([]).sort(FunnyKey.sorter)).toEqual(items)

    describe "some of which are then removed", ->
      ex_keys = keys[0..100]
      h = hash.minus ex_keys...

      it "should have the correct size", ->
        expect(h.size()).toEqual keys.length - ex_keys.length

      it "should not be the same as the original hash", ->
        expect(h).not.toEqual hash

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

      it "should retrieve the associated values for the remaining keys", ->
        expect(h.get(key)).toBe key.value for key in keys when key not in ex_keys

      it "should not return anything for the removed keys", ->
        expect(h.get(key)).not.toBeDefined() for key in ex_keys

      it "should have exactly the remaining elements when made an array", ->
        expect(h.toArray().sort(FunnyKey.sorter)).toEqual(items[101..])

    describe "from which some keys not included are removed", ->
      ex_keys = (new FunnyKey(x) for x in [1000..1100])
      h = hash.minus ex_keys...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the correct size", ->
        expect(h.size()).toEqual hash.size()

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

      it "should retrieve the associated values for the original keys", ->
        expect(h.get(key)).toBe key.value for key in keys

      it "should not return anything for the 'removed' keys", ->
        expect(h.get(key)).not.toBeDefined() for key in ex_keys

      it "should have exactly the original items as an array", ->
        expect(h.toArray().sort(FunnyKey.sorter)).toEqual items

    describe "all of which are then removed", ->
      h = hash.minus keys...

      it "should have size 0", ->
        expect(h.size()).toEqual 0

      it "should be empty", ->
        expect(h.size()).toBe 0

      it "should return nothing for the removed keys", ->
        expect(h.get(key)).not.toBeDefined() for key in keys

      it "should convert to an empty array", ->
        expect(h.toArray().length).toBe 0

    describe "some of which are then replaced", ->
      ex_keys = keys[0..100]
      newItems = ([k, k.value.toString()] for k in ex_keys)
      h = hash.plus newItems...

      it "should have the same size as before", ->
        expect(h.size()).toBe hash.size()

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

      it "should retrieve the original values for the untouched keys", ->
        expect(h.get(key)).toBe key.value for key in keys when key not in ex_keys

      it "should return the new values for the modified keys", ->
        expect(h.get(key)).toBe key.value.toString() for key in ex_keys

      it "should contain the appropriate key-value pairs", ->
        a = h.toArray().sort(FunnyKey.sorter)
        expect(a[101..]).toEqual items[101..]
        expect(a[0..100]).toEqual ([k, v.toString()] for [k, v] in items[0..100])

    describe "some of which are then overwritten with the original value", ->
      ex_keys = keys[0..100]
      newItems = ([k, k.value] for k in ex_keys)
      h = hash.plus newItems...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the same size as before", ->
        expect(h.size()).toEqual hash.size()

      it "should not be empty", ->
        expect(h.size()).toBeGreaterThan 0

      it "should retrieve the original values for all keys", ->
        expect(h.get(key)).toBe key.value for key in keys

      it "should contain the appropriate key-value pair", ->
        expect(h.toArray().sort(FunnyKey.sorter)).toEqual items
