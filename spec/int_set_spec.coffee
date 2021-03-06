if typeof(require) != 'undefined'
  { seq }    = require 'sequence'
  { IntSet } = require 'indexed'
else
  { seq, IntSet } = pazy


describe "An IntSet", ->

	describe "with two items the first of which is removed", ->
    hash = new IntSet().plus(37).plus(42).minus(37)

    it "should have size 1", ->
      expect(hash.size()).toBe 1

    it "should not be the same object as another one constructed like it", ->
      expect(hash).not.toBe(new IntSet().plus(37).plus(42).minus(37))


  describe "when empty", ->
    hash = new IntSet()

    it "should have size 0", ->
      expect(hash.size()).toEqual 0

    it "should return false on contains", ->
      expect(hash.contains(1337)).toBe false

    it "should still be empty when minus is called", ->
      expect(hash.minus(1337).size()).toEqual 0

    it "should have length 0 as an array", ->
      expect(hash.toArray().length).toEqual 0

    it "should print as IntSet(EmptyNode)", ->
      expect(hash.toString()).toEqual('IntSet(EmptyNode)')


  describe "containing one item", ->
    hash = new IntSet().plus(1337)

    it "should have size 1", ->
      expect(hash.size()).toEqual 1

    it "should have size 0 when the item is removed", ->
      expect(hash.minus(1337).size()).toBe 0

    it "should have size 0 when the item is removed twice", ->
      expect(hash.minus(1337, 1337).size()).toBe 0

    it "should return true for the key", ->
      expect(hash.contains(1337)).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains(4023)).toBe false

    it "should contain the key", ->
      a = hash.toArray()
      expect(a.length).toEqual 1
      expect(a).toContain(1337)

    it "should print as IntSet(1337)", ->
      expect(hash.toString()).toEqual('IntSet(1337)')


  describe "containing two items", ->
    hash = new IntSet().plus(1337).plus(4023)

    it "should have size 2", ->
      expect(hash.size()).toEqual 2

    it "should not be empty when the first item is removed", ->
      expect(hash.minus(1337).size()).toBeGreaterThan 0

    it "should be empty when both items are removed", ->
      expect(hash.minus(4023).minus(1337).size()).toBe 0

    it "should return true for both keys", ->
      expect(hash.contains(1337)).toBe true
      expect(hash.contains(4023)).toBe true

    it "should return false when fed another key", ->
      expect(hash.contains(65535)).toBe false

    it "should contain the keys", ->
      a = hash.toArray()
      expect(a.length).toEqual 2
      expect(a).toContain(1337)
      expect(a).toContain(4023)

    it "should not change when illegal items are added", ->
      expect(hash.plus("a", -1, 2.34, 0x100000000, [1], {1:2})).toBe hash

    it "should not change when illegal items are removed", ->
      expect(hash.minus("a", -1, 2.34, 0x100000000, [1], {1:2})).toBe hash


  describe "containing eight items with collisions in the lower bits", ->
    keys = [
      0x1fffffff
      0x3fffffff
      0x5ff0ffff
      0x7ff0ffff
      0x9fffffff
      0xbfffffff
      0xdff0ffff
      0xfff0ffff
    ]
    hash = new IntSet().plus keys...

    it "should return true for all keys", ->
      expect(hash.contains(key)).toBe true for key in keys

    it "should have size 1 when all items but one are removed", ->
      expect(hash.minus((keys[i] for i in [0..6])...).size()).toEqual 1

    it "should be empty when all items are removed", ->
      expect(hash.minus(keys...).size()).toBe 0


  describe "containing four items with collisions in the higher bits", ->
    key_a = 0x7ffffff1
    key_b = 0x7ffffff3
    key_c = 0x7fff0ff5
    key_d = 0x7fff0ff7
    hash = new IntSet().plus(key_a, key_b, key_c, key_d)

    it "should return true for all keys", ->
      expect(hash.contains(key_a)).toBe true
      expect(hash.contains(key_b)).toBe true
      expect(hash.contains(key_c)).toBe true
      expect(hash.contains(key_d)).toBe true

    it "should have size 1 when all items but one are removed", ->
      expect(hash.minus(key_a, key_b, key_c).size()).toEqual 1

    it "should be empty when all items are removed", ->
      expect(hash.minus(key_a, key_b, key_c, key_d).size()).toBe 0


  describe "containing three items", ->
    key_a = 257
    key_b = 513
    key_c = 769
    hash = new IntSet().plus(key_a).plus(key_b).plus(key_c)

    it "should contain the remaining two items when one is removed", ->
      a = hash.minus(key_a).toArray()
      expect(a.length).toEqual 2
      expect(a).toContain key_b
      expect(a).toContain key_c

    it "should contain four items when one with a new hash value is added", ->
      key_d = 33
      a = hash.plus(key_d).toArray()
      expect(a.length).toEqual 4
      expect(a).toContain key_a
      expect(a).toContain key_b
      expect(a).toContain key_c
      expect(a).toContain key_d

  describe "containing a wild mix of items", ->
    keys = (x * 5 + 7 for x in [0..16])
    hash = (new IntSet()).plus keys...

    it "should have the right number of items", ->
      expect(hash.size()).toEqual keys.length

    it "should return true for each key", ->
      expect(hash.contains(key)).toBe true for key in keys


  describe "containing lots of items", ->
    keys = [0..300]
    hash = (new IntSet()).plus keys...

    it "should have the correct number of keys", ->
      expect(hash.size()).toEqual keys.length

    it "should return true for each key", ->
      expect(hash.contains(key)).toBe true for key in keys

    it "should return false when fed another key", ->
      expect(hash.contains("third")).toBe false

    it "should contain all the keys when converted to an array", ->
      expect(hash.toArray()).toEqual(keys)

    it "should have the first key as its first element", ->
      expect(seq.get hash, 0).toEqual(keys[0])

    it "should have the second key as its second element", ->
      expect(seq.get hash, 1).toEqual(keys[1])

    it "should have the last key as its last element", ->
      expect(seq.last hash).toEqual(keys[300])

    describe "some of which are then removed", ->
      ex_keys = keys[0..100]
      h = hash.minus ex_keys...

      it "should have the correct size", ->
        expect(h.size()).toEqual keys.length - ex_keys.length

      it "should not be the same as the original hash", ->
        expect(h).not.toEqual hash

      it "should return true for the remaining keys", ->
        expect(h.contains(key)).toBe true for key in keys when key not in ex_keys

      it "should return false for the removed keys", ->
        expect(h.contains(key)).toBe false for key in ex_keys

      it "should have exactly the remaining elements when made an array", ->
        expect(h.toArray()).toEqual(keys[101..])

    describe "from which some keys not included are removed", ->
      ex_keys = [1000..1100]
      h = hash.minus ex_keys...

      it "should be the same object as before", ->
        expect(h).toBe hash

      it "should have the correct size", ->
        expect(h.size()).toEqual hash.size()

    describe "all of which are then removed", ->
      h = hash.minus keys...

      it "should have size 0", ->
        expect(h.size()).toEqual 0

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
