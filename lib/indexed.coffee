# --------------------------------------------------------------------
# A number of collection classes based on Rich Hickey's persistent
# hash trie implementation from Clojure (http://clojure.org), which
# was originally introduced as a mutable data structure in a paper by
# Phil Bagwell.
#
# To simplify the logic downstream, all node classes assume that
# plus() or minus() are only ever called if they would result in a
# changed node. This has therefore to be assured by the caller, and
# ultimately by the collection classes themselves.
#
# This version: Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
#
# Original copyright and licensing:
# --------------------------------------------------------------------
# Copyright (c) Rich Hickey. All rights reserved.
# The use and distribution terms for this software are covered by the
# Eclipse Public License 1.0 (http://opensource.org/licenses/eclipse-1.0.php)
# which can be found in the file epl-v10.html at the root of this distribution.
# By using this software in any fashion, you are agreeing to be bound by
# the terms of this license.
# You must not remove this notice, or any other, from this software.
# --------------------------------------------------------------------

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Sequence } = require('sequence')
else
  { Sequence } = this.pazy


# --------------------------------------------------------------------
# Nodes and support functions used by several collections.
# --------------------------------------------------------------------

# A collection of utility functions used by interior nodes.
util = {
  arrayWith: (a, i, x) ->
    (if j == i then x else a[j]) for j in [0...a.length]

  arrayWithInsertion: (a, i, x) ->
    (if j < i then a[j] else if j > i then a[j-1] else x) for j in [0..a.length]

  arrayWithout: (a, i) ->
    a[j] for j in [0...a.length] when j != i


  isKey: (n) -> typeof(n) == "number" and (0x100000000 > n >= 0) and (n % 1 == 0)

  mask: (key, shift) -> (key >> (27 - shift)) & 0x1f

  bitCount: (n) ->
    n -= (n >> 1) & 0x55555555
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    n = (n & 0x0f0f0f0f) + ((n >> 4) & 0x0f0f0f0f)
    n += n >> 8
    (n + (n >> 16)) & 0x3f

  indexForBit: (bitmap, bit) -> util.bitCount(bitmap & (bit - 1))

  bitPosAndIndex: (bitmap, key, shift) ->
    bit = 1 << util.mask(key, shift)
    [bit, util.indexForBit(bitmap, bit)]
}


# A node with no entries. We need only one of those.
EmptyNode = {
  size:    0

  get:     (shift, key, data) -> undefined

  elements: null

  plus:    (shift, key, leaf) -> leaf

  minus: (shift, key, data) -> this

  toString: -> "EmptyNode"
}


# A sparse interior node using a bitmap to indicate which of the
# indices 0..31 are in use.
class BitmapIndexedNode
  constructor: (bitmap, progeny, size) ->
    [@bitmap, @progeny, @size] = if arguments.length == 0
      [0, [], 0]
    else
      [bitmap, progeny, size]

    @elements = Sequence.flatMap @progeny, (n) -> n?.elements

  get: (shift, key, data) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)
    @progeny[i].get(shift + 5, key, data) if (@bitmap & bit) != 0

  plus: (shift, key, leaf) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)

    if (@bitmap & bit) == 0
      n = util.bitCount(@bitmap)
      if n < 8
        newArray = util.arrayWithInsertion(@progeny, i, leaf)
        new BitmapIndexedNode(@bitmap | bit, newArray, @size + 1)
      else
        progeny = for m in [0..31]
          b = 1 << m
          @progeny[util.indexForBit(@bitmap, b)] if (@bitmap & b) != 0
        new ArrayNode(progeny, util.mask(key, shift), leaf, @size + 1)
    else
      v = @progeny[i]
      node = v.plus(shift + 5, key, leaf)
      if @bitmap == (1 << i)
        new ProxyNode(i, node)
      else
        array = util.arrayWith(@progeny, i, node)
        new BitmapIndexedNode(@bitmap, array, @size + node.size - v.size)

  minus: (shift, key, data) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)

    v = @progeny[i]
    node = v.minus(shift + 5, key, data)
    if node?
      newBitmap = @bitmap
      newSize   = @size + node.size - v.size
      newArray  = util.arrayWith(@progeny, i, node)
    else
      newBitmap = @bitmap ^ bit
      newSize   = @size - 1
      newArray  = util.arrayWithout(@progeny, i)

    bits = util.bitCount(newBitmap)
    if bits == 0
      null
    else if bits == 1
      node = newArray[0]
      if node.progeny?
        new ProxyNode(util.bitCount(newBitmap - 1), node)
      else
        node
    else
      new BitmapIndexedNode(newBitmap, newArray, newSize)

  toString: (prefix = '') ->
    pre = prefix + ' '
    buf = []
    for m in [0..31]
      b = 1 << m
      if (@bitmap & b) != 0
        buf.push @progeny[util.indexForBit(@bitmap, b)].toString(pre)
    if buf.length == 1
      '{' + buf[0] + '}'
    else
      buf.unshift ''
      '{' + buf.join('\n' + pre) + '}'


# Special case of a sparse interior node which has exactly one descendant.
class ProxyNode
  constructor: (@child_index, @progeny) ->
    @size     = @progeny.size
    @elements = @progeny.elements

  get: (shift, key, data) ->
    @progeny.get(shift + 5, key, data) if @child_index == util.mask(key, shift)

  plus: (shift, key, leaf) ->
    i = util.mask(key, shift)

    if @child_index == i
      new ProxyNode(i, @progeny.plus(shift + 5, key, leaf))
    else
      bitmap = (1 << @child_index) | (1 << i)
      array = if i < @child_index then [leaf, @progeny] else [@progeny, leaf]
      new BitmapIndexedNode(bitmap, array, @size + leaf.size)

  minus: (shift, key, data) ->
    node = @progeny.minus(shift + 5, key, data)
    if node?.progeny?
      new ProxyNode(@child_index, node)
    else
      node

  toString: (prefix = '') -> '.' + @progeny.toString(prefix + ' ')


# A dense interior node with room for 32 entries.
class ArrayNode
  constructor: (progeny, i, node, @size) ->
    @progeny  = util.arrayWith(progeny, i, node)
    @elements = Sequence.select(@progeny, (x) -> x).flatMap (n) -> n.elements

    #TODO - why does this not work:
    #@elements = Sequence.flatMap @progeny, (n) -> n?.elements

  get: (shift, key, data) ->
    i = util.mask(key, shift)
    @progeny[i].get(shift + 5, key, data) if @progeny[i]?

  plus: (shift, key, leaf) ->
    i = util.mask(key, shift)

    if @progeny[i]?
      node = @progeny[i].plus(shift + 5, key, leaf)
      newSize = @size + node.size - @progeny[i].size
      new ArrayNode(@progeny, i, node, newSize)
    else
      new ArrayNode(@progeny, i, leaf, @size + 1)

  minus: (shift, key, data) ->
    i = util.mask(key, shift)

    node = @progeny[i].minus(shift + 5, key, data)
    if node?
      new ArrayNode(@progeny, i, node, @size - 1)
    else
      remaining = (j for j in [1...@progeny.length] when j != i and @progeny[j])
      if remaining.length <= 4
        bitmap = Sequence.reduce(remaining, 0, (b, j) -> b | (1 << j))
        array  = (@progeny[j] for j in remaining)
        new BitmapIndexedNode(bitmap, array, @size - 1)
      else
        new ArrayNode(@progeny, i, null, @size - 1)

  toString: (prefix = '') ->
    pre = prefix + ' '
    buf = (x.toString(pre) for x in @progeny when x?)
    if buf.length == 1
      '[' + buf[0] + ']'
    else
      buf.unshift ''
      '[' + buf.join('\n' + pre) + ']'

# --------------------------------------------------------------------
# A common base class for all collection wrappers.
# --------------------------------------------------------------------

class Collection
  # The constructor takes a root node, defaulting to empty.
  constructor: (@root) ->
    @root ?= EmptyNode
    @entries = @root?.elements

  size: -> @root.size

  # If called with a block, iterates over the elements in this set;
  # otherwise, returns this set (this mimics Ruby enumerables).
  each: (func) -> if func? then @entries?.each(func) else this

  # Generic update method
  update_: (root) -> if root != @root then new @constructor(root) else this

  # Returns a new set with the given keys inserted as elements, or
  # this set if it already contains all those elements.
  plus: -> @plusAll new Sequence arguments

  # Like plus, but takes a sequence of keys
  plusAll: (seq) -> @update_ seq.reduce @root, @constructor.plusOne

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  minus: -> @minusAll new Sequence arguments

  # Like plus, but takes a sequence of keys
  minusAll: (seq) -> @update_ seq.reduce @root, @constructor.minusOne

  # Creates a mapped collection of the same type
  map: (fun) -> new @constructor().plusAll @entries.map fun

  # The sequence of entries.
  toSeq: -> @entries

  # Returns the elements in this set as an array.
  toArray: -> Sequence.into @entries, []

  # Returns a string representation of this collection.
  toString: -> "#{@constructor.name}(#{@root})"


# --------------------------------------------------------------------
# Collections with integer keys.
# --------------------------------------------------------------------

# A leaf node containing a single integer.
class IntLeaf
  constructor: (@key) ->
    @elements = Sequence.conj @key

  size: 1

  get:  (shift, key, data) -> key == @key

  plus: (shift, key, leaf) ->
    new BitmapIndexedNode().plus(shift, @key, this).plus(shift, key, leaf)

  minus: (shift, key, data) -> null

  toString: -> "#{@key}"


# The IntSet class.
class IntSet extends Collection
  @name = "IntSet"

  # Returns true or false depending on whether the given key is an
  # element of this set.
  contains: (key) -> @root.get(0, key) == true

  @plusOne: (root, key) ->
    if util.isKey(key) and not root.get(0, key)
      root.plus(0, key, new IntLeaf(key))
    else
      root

  @minusOne: (root, key) ->
    if util.isKey(key) and root?.get(0, key)
      root.minus(0, key)
    else
      root


# A leaf node with an integer key and arbitrary value.
class IntLeafWithValue
  constructor: (@key, @value) ->
    @elements = Sequence.conj [@key, @value]

  size: 1

  get:  (shift, key, data) -> @value if key == @key

  plus: (shift, key, leaf) ->
    if @key == key
      leaf
    else
      new BitmapIndexedNode().plus(shift, @key, this).plus(shift, key, leaf)

  minus: (shift, key, data) -> null

  toString: -> "#{@key} ~> #{@value}"


# The IntMap class is essentially a huge sparse array.
class IntMap extends Collection
  @name = "IntMap"

  # Returns true or false depending on whether the given key is an
  # element of this set.
  get: (key) -> @root.get(0, key)

  @plusOne: (root, [key, value]) ->
    if util.isKey(key) and not areEqual(root.get(0, key), value)
      root.plus(0, key, new IntLeafWithValue(key, value))
    else
      root

  @minusOne: (root, key) ->
    if util.isKey(key) and typeof(root?.get(0, key)) != 'undefined'
      root.minus(0, key)
    else
      root


# --------------------------------------------------------------------
# Support for collections that use hashing.
# --------------------------------------------------------------------

hashStep = (code, c) -> (code * 37 + c.charCodeAt(0)) & 0xffffffff

hashCode = (obj) ->
  if obj? and typeof(obj.hashCode) == "function"
    code = obj.hashCode()
    if util.isKey code
      return code

  stringVal =
    if typeof(obj) == "string"
      obj
    else if typeof(obj) == "object"
      ("#{k}:#{v}" for k,v of obj).join(",")
    else if obj? and typeof(obj.toString) == "function"
      obj.toString()
    else
      try
        String(obj)
      catch ex
        Object::toString.call(obj)

  Sequence.reduce(stringVal, 0, hashStep)

areEqual = (obj1, obj2) ->
  if obj1? and typeof(obj1.equals) == "function"
    obj1.equals(obj2)
  else if obj2? and typeof(obj2.equals) == "function"
    obj2.equals(obj1)
  else
    obj1 == obj2


# A collision node contains several leaf nodes, stored in an array
# @bucket, in which all keys share a common hash value.
class CollisionNode
  constructor: (@hash, @bucket) ->
    @bucket   = [] unless @bucket?
    @size     = @bucket.length
    @elements = Sequence.flatMap @bucket, (n) -> n?.elements

  get: (shift, hash, key) ->
    leaf = Sequence.find @bucket, (v) -> areEqual(v.key, key)
    leaf.get(shift, hash, key) if leaf?

  plus: (shift, hash, leaf) ->
    if hash != @hash
      new BitmapIndexedNode().plus(shift, @hash, this).plus(shift, hash, leaf)
    else
      newBucket = this.bucketWithout(leaf.key)
      newBucket.push leaf
      new CollisionNode(hash, newBucket)

  minus: (shift, hash, key) ->
    switch @bucket.length
      when 0, 1 then null
      when 2    then Sequence.find @bucket, (v) -> not areEqual(v.key, key)
      else           new CollisionNode(hash, this.bucketWithout(key))

  toString: -> "#{@bucket.join("|")}"

  bucketWithout: (key) ->
    item for item in @bucket when not areEqual(item.key, key)


# --------------------------------------------------------------------
# The hash set collection class and its leaf nodes.
# --------------------------------------------------------------------

# A leaf node contains a single key and also caches its hash value.
class HashLeaf
  constructor: (@hash, @key) ->
    @elements = Sequence.conj @key

  size: 1

  get:  (shift, hash, key) -> true if areEqual(key, @key)

  plus: (shift, hash, leaf) ->
    if hash == @hash
      base = new CollisionNode(hash)
    else
      base = new BitmapIndexedNode()
    base.plus(shift, @hash, this).plus(shift, hash, leaf)

  minus: (shift, hash, key) -> null

  toString: -> "#{@key}"


# The HashSet class provides the public API and serves as a wrapper
# for the various node classes that hold the actual information.
class HashSet extends Collection
  @name = "HashSet"

  # Returns true or false depending on whether the given key is an
  # element of this set.
  contains: (key) -> @root.get(0, hashCode(key), key) == true

  @plusOne: (root, key) ->
    hash = hashCode(key)
    if root.get(0, hash, key)
      root
    else
      root.plus(0, hash, new HashLeaf(hash, key))

  @minusOne: (root, key) ->
    hash = hashCode(key)
    if root?.get(0, hash, key)
      root.minus(0, hash, key)
    else
      root


# --------------------------------------------------------------------
# The hash map collection class and its leaf nodes.
# --------------------------------------------------------------------

# A leaf node contains a single key-value pair and also caches the
# hash value for the key.
class HashLeafWithValue
  constructor: (@hash, @key, @value) ->
    @elements = Sequence.conj [@key, @value]

  size: 1

  get:  (shift, hash, key) -> @value if areEqual(key, @key)

  plus: (shift, hash, leaf) ->
    if areEqual(@key, leaf.key)
      leaf
    else
      if hash == @hash
        base = new CollisionNode(hash)
      else
        base = new BitmapIndexedNode()
      base.plus(shift, @hash, this).plus(shift, hash, leaf)

  minus: (shift, hash, key) -> null

  toString: -> "#{@key} ~> #{@value}"


# The HashMap class provides the public API and serves as a wrapper
# for the various node classes that hold the actual information.
class HashMap extends Collection
  @name = "HashMap"

  # Retrieves the value associated with the given key, or nil if the
  # key is not present.
  get: (key) -> @root.get(0, hashCode(key), key)

  @plusOne: (root, [key, value]) ->
    hash = hashCode(key)
    if areEqual(root.get(0, hash, key), value)
      root
    else
      root.plus(0, hash, new HashLeafWithValue(hash, key, value))

  @minusOne: (root, key) ->
    hash = hashCode(key)
    if typeof(root?.get(0, hash, key)) != 'undefined'
      root.minus(0, hash, key)
    else
      root


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.IntSet  = IntSet
exports.IntMap  = IntMap
exports.HashMap = HashMap
exports.HashSet = HashSet
