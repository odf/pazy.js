require.paths.unshift './lib'

IntSet = require('collections').IntSet

intSorter = (a, b) -> a - b


describe "An IntSet", ->

	describe "with two items the first of which is removed", ->
    hash = new IntSet().plus(37).plus(42).minus(37)

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should not be the same object as another one constructed like it", ->
      expect(hash).not.toBe(new IntSet().plus(37).plus(42).minus(37))


  describe "when empty", ->
    hash = new IntSet()

    it "should have size 0", ->
      expect(hash.size).toEqual 0

    it "should be empty", ->
      expect(hash.isEmpty).toBe true

    it "should return false on get", ->
      expect(hash.get("first")).toBe false

    it "should still be empty when without is called", ->
      expect(hash.without("first").size).toEqual 0

    it "should have length 0 as an array", ->
      expect(hash.toArray().length).toEqual 0

    it "should print as IntSet(EmptyNode)", ->
      expect(hash.toString()).toEqual('IntSet(EmptyNode)')


  describe "containing one item", ->
    hash = new IntSet().with(1337)

    it "should have size 1", ->
      expect(hash.size).toEqual 1

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should be empty when the item is removed", ->
      expect(hash.without(1337).isEmpty).toBe true

    it "should return true for the key", ->
      expect(hash.get(1337)).toBe true

    it "should return false when fed another key", ->
      expect(hash.get(4023)).toBe false

    it "should contain the key", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain(1337)

    it "should print as IntSet(LeafNode(1337))", ->
      expect(hash.toString()).toEqual('IntSet(LeafNode(1337))')


  describe "containing two items", ->
    hash = new IntSet().with(1337).with(4023)

    it "should have size 2", ->
      expect(hash.size).toEqual 2

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should not be empty when the first item is removed", ->
      expect(hash.without(1337).isEmpty).toBe false

    it "should be empty when both items are removed", ->
      expect(hash.without(4023).without(1337).isEmpty).toBe true

    it "should return true for both keys", ->
      expect(hash.get(1337)).toBe true
      expect(hash.get(4023)).toBe true

    it "should return false when fed another key", ->
      expect(hash.get(65535)).toBe false

    it "should contain the keys", ->
      a = hash.toArray()
      expect(a.length).toEqual 2
      expect(a).toContain(1337)
      expect(a).toContain(4023)


  describe "containing two items with a level 1 collision", ->
    key_a = 1
    key_b = 33
    hash = new IntSet().with(key_a).with(key_b)

    it "should not change when an item not included is removed", ->
      a = hash.without(5).toArray()
      expect(a.length).toEqual 2
      expect(a).toContain key_a
      expect(a).toContain key_b

    it "should return true for both keys", ->
      expect(hash.get(key_a)).toBe true
      expect(hash.get(key_b)).toBe true

    it "should not be empty when the first item is removed", ->
      expect(hash.without(key_a).isEmpty).toBe false

    it "should have size 1 when the first item is removed", ->
      expect(hash.without(key_a).size).toEqual 1

    it "should be empty when both items are removed", ->
      expect(hash.without(key_a).without(key_b).isEmpty).toBe true


  describe "containing three items", ->
    key_a = 257
    key_b = 513
    key_c = 769
    hash = new IntSet().with(key_a).with(key_b).with(key_c)

    it "should contain the remaining two items when one is removed", ->
      a = hash.without(key_a).toArray()
      expect(a.length).toEqual 2
      expect(a).toContain key_b
      expect(a).toContain key_c

    it "should contain four items when one with a new hash value is added", ->
      key_d = 33
      a = hash.with(key_d).toArray()
      expect(a.length).toEqual 4
      expect(a).toContain key_a
      expect(a).toContain key_b
      expect(a).toContain key_c
      expect(a).toContain key_d

  describe "containing a wild mix of items", ->
    keys = x * 5 + 7 for x in [0..16]
    hash = (new IntSet()).with keys...

    it "should have the right number of items", ->
      expect(hash.size).toEqual keys.length

    it "should return true for each key", ->
      expect(hash.get(key)).toBe true for key in keys


  describe "containing lots of items", ->
    keys = [0..300]
    hash = (new IntSet()).with keys...

    it "should have the correct number of keys", ->
      expect(hash.size).toEqual keys.length

    it "should not be empty", ->
      expect(hash.isEmpty).toBe false

    it "should return true for each key", ->
      expect(hash.get(key)).toBe true for key in keys

    it "should return false when fed another key", ->
      expect(hash.get("third")).toBe false

    it "should contain all the keys when converted to an array", ->
      expect(hash.toArray().sort(intSorter)).toEqual(keys)

    describe "some of which are then removed", ->
      ex_keys = keys[0..100]
      h = hash.without ex_keys...

      it "should have the correct size", ->
        expect(h.size).toEqual keys.length - ex_keys.length

      it "should not be the same as the original hash", ->
        expect(h).not.toEqual hash

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

      it "should return true for the remaining keys", ->
        expect(h.get(key)).toBe true for key in keys when not key in ex_keys

      it "should return false for the removed keys", ->
        expect(h.get(key)).toBe false for key in ex_keys

      it "should have exactly the remaining elements when made an array", ->
        expect(h.toArray().sort(intSorter)).toEqual(keys[101..])

    describe "from which some keys not included are removed", ->
      ex_keys = [1000..1100]
      h = hash.without ex_keys...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the correct size", ->
        expect(h.size).toEqual hash.size

      it "should not be empty", ->
        expect(h.isEmpty).toBe false

    describe "all of which are then removed", ->
      h = hash.without keys...

      it "should have size 0", ->
        expect(h.size).toEqual 0

      it "should be empty", ->
        expect(h.isEmpty).toBe true

      it "should return false for the removed keys", ->
        expect(h.get(key)).toBe false for key in keys

      it "should convert to an empty array", ->
        expect(h.toArray().length).toBe 0

    describe "some of which are then inserted again", ->
      ex_keys = keys[0..100]
      h = hash.with ex_keys...

      it "should be the same object as before", ->
         expect(h).toBe hash

      it "should have the same size as before", ->
        expect(h.size).toEqual hash.size

      it "should not be empty", ->
        expect(h.isEmpty).toBe false