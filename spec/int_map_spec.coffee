if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  IntMap = require('indexed').IntMap
else
  IntMap = pazy.IntMap

describe "An IntMap", ->

	describe "with two items the first of which is removed", ->
    hash = new IntMap().plus([37, true]).plus([42, true]).minus(37)

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should not be the same object as another one constructed like it", ->
      h = new IntMap().plus([37, true]).plus([42, true]).minus(37)
      expect(hash).not.toBe h


  describe "when empty", ->
    hash = new IntMap()

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
      expect(hash.toString()).toEqual('IntMap(EmptyNode)')


  describe "containing one item", ->
    hash = new IntMap().with([1337, 1])

    it "should have size 1", ->
      expect(hash.size).toEqual 1

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should retrieve the associated value for the key", ->
      expect(hash.get(1337)).toBe 1

    it "should not return anything when fed another key", ->
      expect(hash.get(4023)).not.toBeDefined()

    it "should be empty when the item is removed", ->
      expect(hash.without(1337).isEmpty).toBe true

    it "should contain the key-value pair", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain([1337, 1])

    it "should print as IntMap(LeafNode(1337, 1))", ->
      expect(hash.toString()).toEqual('IntMap(LeafNode(1337, 1))')

    describe "the value of which is then changed", ->
      h = hash.with([1337, "leet!"])

      it "should have size 1", ->
        expect(h.size).toBe 1

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should retrieve the associated value for the key", ->
        expect(h.get(1337)).toBe "leet!"

      it "should not return anything when fed another key", ->
        expect(h.get(4023)).not.toBeDefined()

      it "should contain the new key-value pair", ->
        a = h.toArray()
        expect(a.length).toEqual 1
        expect(a).toContain([1337, "leet!"])


  describe "containing two items", ->
    hash = new IntMap().with([1337, 'leet!']).with([4023, 'lame?'])

    it "should have size 2", ->
      expect(hash.size).toEqual 2

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should not be empty when the first item is removed", ->
      expect(hash.without(1337).isEmpty).toBe false

    it "should be empty when both items are removed", ->
      expect(hash.without(4023).without(1337).isEmpty).toBe true

    it "should return the associate values for both keys", ->
      expect(hash.get(1337)).toBe 'leet!'
      expect(hash.get(4023)).toBe 'lame?'

    it "should not return anything when fed another key", ->
      expect(hash.get(65535)).not.toBeDefined()

    it "should contain the key-value pairs", ->
      a = hash.toArray()
      expect(a.length).toEqual 2
      expect(a).toContain([1337, 'leet!'])
      expect(a).toContain([4023, 'lame?'])

    it "should not change when illegal items are added", ->
      expect(hash.with ["a", 1], [-1, 2], [0x100000000, 4]).toBe hash
      expect(hash.with [2.34, 3], [[1], 5], [{1:2}, 6]).toBe hash

    it "should not change when illegal items are removed", ->
      expect(hash.without("a", -1, 2.34, 0x100000000, [1], {1:2})).toBe hash


  describe "containing four items with collisions in the lower bits", ->
    keys = [0x1fffffff, 0x3fffffff, 0x5ff0ffff, 0x7ff0ffff]
    items = [key, "0x#{key.toString(16)}"] for key in keys
    hash = (new IntMap()).with items...

    it "should return the associated value for all keys", ->
      expect(hash.get(key)).toBe value for [key, value] in items

    it "should not be empty when all items but one are removed", ->
      expect(hash.without(keys[0..2]...).isEmpty).toBe false

    it "should have size 1 when all items but one are removed", ->
      expect(hash.without(keys[0..2]...).size).toEqual 1

    it "should be empty when all items are removed", ->
      expect(hash.without(keys...).isEmpty).toBe true


  describe "containing four items with collisions in the higher bits", ->
    keys = [0x7ffffff1, 0x7ffffff3, 0x7fff0ff5, 0x7fff0ff7]
    items = [key, "0x#{key.toString(16)}"] for key in keys
    hash = (new IntMap()).with items...

    it "should return the associated value for all keys", ->
      expect(hash.get(key)).toBe value for [key, value] in items

    it "should not be empty when all items but one are removed", ->
      expect(hash.without(keys[0..2]...).isEmpty).toBe false

    it "should have size 1 when all items but one are removed", ->
      expect(hash.without(keys[0..2]...).size).toEqual 1

    it "should be empty when all items are removed", ->
      expect(hash.without(keys...).isEmpty).toBe true


  describe "containing three items", ->
    key_a = 257
    key_b = 513
    key_c = 769
    key_d = 33
    hash = new IntMap().with([key_a, "a"], [key_b, "b"], [key_c, "c"])

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
    keys  = (x * 5 + 7) for x in [0..16]
    items = [key, key.toString()] for key in keys
    scrambled = items[(i * 7) % 17] for i in [0..16]
    hash  = (new IntMap()).with scrambled...

    it "should have the right number of items", ->
      expect(hash.size).toEqual keys.length

    it "should retrieve the associated value for each key", ->
      expect(hash.get(key)).toBe value for [key, value] in items

    it "should contain all the items when converted to an array", ->
      expect(hash.toArray()).toEqual(items)


  describe "containing lots of items", ->
    keys  = [0..306]
    items = [key, key.toString()] for key in keys
    scrambled = items[(i * 127) % 307] for i in [0..306]
    hash  = (new IntMap()).with items...

    it "should have the correct number of items", ->
      expect(hash.size).toEqual keys.length

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should retrieve the associated value for each key", ->
      expect(hash.get(key)).toBe value for [key, value] in items

    it "should not return anythin when fed another key", ->
      expect(hash.get(500)).not.toBeDefined()

    it "should contain all the items when converted to an array", ->
      expect(hash.toArray()).toEqual(items)


    describe "some of which are then removed", ->
      ex_keys = keys[(i * 37) % 101] for i in [0..100]
      h = hash.without ex_keys...

      it "should have the correct size", ->
        expect(h.size).toEqual keys.length - ex_keys.length

      it "should not be the same as the original hash", ->
        expect(h).not.toEqual hash

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should retrieve the associated values for the remaining keys", ->
        expect(h.get(key)).toBe value for [key, value] in items[101..]

      it "should not return anything for the removed keys", ->
        expect(h.get(key)).not.toBeDefined() for key in ex_keys

      it "should have exactly the remaining elements when made an array", ->
        expect(h.toArray()).toEqual(items[101..])

    describe "from which some keys not included are removed", ->
      ex_keys = keys[(i * 37) % 101 + 1000] for i in [0..100]
      h = hash.without ex_keys...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the correct size", ->
        expect(h.size).toEqual hash.size

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should retrieve the associated values for the original keys", ->
        expect(h.get(key)).toBe value for [key, value] in items

      it "should not return anything for the 'removed' keys", ->
        expect(h.get(key)).not.toBeDefined() for key in ex_keys

      it "should have exactly the original items as an array", ->
        expect(h.toArray()).toEqual items

    describe "all of which are then removed", ->
      h = hash.without keys...

      it "should have size 0", ->
        expect(h.size).toEqual 0

      it "should be empty", ->
        expect(h.isEmpty).toBe true

      it "should return nothing for the removed keys", ->
        expect(h.get(key)).not.toBeDefined() for key in keys

      it "should convert to an empty array", ->
        expect(h.toArray().length).toBe 0

    describe "some of which are then replaced", ->
      ex_keys = [0..100]
      newItems = [k, "0x#{k.toString(16)}"] for k in ex_keys
      scrambled = newItems[(i * 41) % 101] for i in [0..100]
      h = hash.with scrambled...

      it "should have the same size as before", ->
        expect(h.size).toBe hash.size

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should retrieve the original values for the untouched keys", ->
        expect(h.get(key)).toBe value for [key, value] in items[101..]

      it "should return the new values for the modified keys", ->
        expect(h.get(key)).toBe value for [key, value] in ex_keys

      it "should contain the appropriate key-value pairs", ->
        a = h.toArray()
        expect(a[101..]).toEqual items[101..]
        expect(a[0..100]).toEqual newItems

    describe "some of which are then overwritten with the original value", ->
      scrambled = items[(i * 41) % 101] for i in [0..100]
      h = hash.with scrambled...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the same size as before", ->
        expect(h.size).toEqual hash.size

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should retrieve the original values for all keys", ->
        expect(h.get(key)).toBe value for [key, value] in items

      it "should contain the appropriate key-value pair", ->
        expect(h.toArray()).toEqual items
