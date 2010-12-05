# --------------------------------------------------------------------
# A number of collection classes based on Rich Hickey's persistent
# hash trie implementation from Clojure (http://clojure.org), which
# was originally introduced as a mutable data structure in a paper by
# Phil Bagwell.
#
# To simplify the logic downstream, all node classes assume that
# with() or without() are only ever called if they would result in a
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
  Stream = require('stream').Stream
else
  Stream = pazy.Stream


# --------------------------------------------------------------------
# Nodes and support functions used by several collections.
# --------------------------------------------------------------------

# A collection of utility functions used by interior nodes.
util = {
  find: (a, test) ->
    for x in a
      return x if test(x) == true
    undefined

  reduce: (a, step, init) ->
    result = init
    for x in a
      result = step(result, x)
    result

  arrayWith: (a, i, x) ->
    (if j == i then x else a[j]) for j in [0...a.length]

  arrayWithInsertion: (a, i, x) ->
    (if j < i then a[j] else if j > i then a[j-1] else x) for j in [0..a.length]

  arrayWithout: (a, i) ->
    a[j] for j in [0...a.length] when j != i


  isKey: (n) -> typeof(n) == "number" and (0x80000000 > n >= 0) and (n % 1 == 0)

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

  with:    (shift, key, leaf) -> leaf

  without: (shift, key, data) -> this

  toString: -> "EmptyNode"
}


# A sparse interior node using a bitmap to indicate which of the
# indices 0..31 are in use.
class BitmapIndexedNode
  constructor: (@bitmap, @progeny, @size) ->
    unless @bitmap?
      @bitmap  = 0
      @progeny = []
      @size    = 0

    @elements = Stream.fromArray(@progeny)?.flat_map (n) -> n?.elements

  get: (shift, key, data) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)
    @progeny[i].get(shift + 5, key, data) if (@bitmap & bit) != 0

  with: (shift, key, leaf) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)

    if (@bitmap & bit) == 0
      n = util.bitCount(@bitmap)
      if n < 8
        newArray = util.arrayWithInsertion(@progeny, i, leaf)
        new BitmapIndexedNode(@bitmap | bit, newArray, @size + 1)
      else
        progeny = new Array(32)
        for m in [0..31]
          b = 1 << m
          progeny[m] = @progeny[util.indexForBit(@bitmap, b)] if (@bitmap & b) != 0
        new ArrayNode(progeny, util.mask(key, shift), leaf, @size + 1)
    else
      v = @progeny[i]
      node = v.with(shift + 5, key, leaf)
      if @bitmap == (1 << i)
        new ProxyNode(i, node)
      else
        array = util.arrayWith(@progeny, i, node)
        new BitmapIndexedNode(@bitmap, array, @size + node.size - v.size)

  without: (shift, key, data) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)

    v = @progeny[i]
    node = v.without(shift + 5, key, data)
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

  toString: -> "BitmapIndexedNode(#{@progeny.join(", ")})"


# Special case of a sparse interior node which has exactly one descendant.
class ProxyNode
  constructor: (@child_index, @progeny) ->
    @size     = @progeny.size
    @elements = @progeny.elements

  get: (shift, key, data) ->
    @progeny.get(shift + 5, key, data) if @child_index == util.mask(key, shift)

  with: (shift, key, leaf) ->
    i = util.mask(key, shift)

    if @child_index == i
      new ProxyNode(i, @progeny.with(shift + 5, key, leaf))
    else
      bitmap = (1 << @child_index) | (1 << i)
      array = if i < @child_index then [leaf, @progeny] else [@progeny, leaf]
      new BitmapIndexedNode(bitmap, array, @size + leaf.size)

  without: (shift, key, data) ->
    node = @progeny.without(shift + 5, key, data)
    if node?.progeny?
      new ProxyNode(@child_index, node)
    else
      node

  toString: -> "ProxyNode(#{@progeny})"


# A dense interior node with room for 32 entries.
class ArrayNode
  constructor: (progeny, i, node, @size) ->
    @progeny  = util.arrayWith(progeny, i, node)
    @elements = Stream.fromArray(@progeny)?.flat_map (n) -> n?.elements

  get: (shift, key, data) ->
    i = util.mask(key, shift)
    @progeny[i].get(shift + 5, key, data) if @progeny[i]?

  with: (shift, key, leaf) ->
    i = util.mask(key, shift)

    if @progeny[i]?
      node = @progeny[i].with(shift + 5, key, leaf)
      newSize = @size + node.size - @progeny[i].size
      new ArrayNode(@progeny, i, node, newSize)
    else
      new ArrayNode(@progeny, i, leaf, @size + 1)

  without: (shift, key, data) ->
    i = util.mask(key, shift)

    node = @progeny[i].without(shift + 5, key, data)
    if node?
      new ArrayNode(@progeny, i, node, @size - 1)
    else
      remaining = (j for j in [1...@progeny.length] when j != i and @progeny[j])
      if remaining.length <= 4
        bitmap = util.reduce(remaining, ((b, j) -> b | (1 << j)), 0)
        array  = (@progeny[j] for j in remaining)
        new BitmapIndexedNode(bitmap, array, @size - 1)
      else
        new ArrayNode(@progeny, i, null, @size - 1)

  toString: -> "ArrayNode(#{(x for x in @progeny when x?).join(", ")})"


# --------------------------------------------------------------------
# A common base class for all collection wrappers.
# --------------------------------------------------------------------

class Collection
  # The constructor takes a root node, defaulting to empty.
  constructor: (@root) ->
    @root ?= EmptyNode
    @size = @root.size
    @isEmpty = @size == 0
    @entries = @root?.elements

  # If called with a block, iterates over the elements in this set;
  # otherwise, returns this set (this mimics Ruby enumerables).
  each: (func) -> if func? then @entries?.each(func) else this

  # Returns the elements in this set as an array.
  toArray: -> @entries?.toArray() or []

  # Returns a string representation of this collection.
  toString: -> "#{@className}(#{@root})"


# --------------------------------------------------------------------
# Collections with integer keys.
# --------------------------------------------------------------------

# A leaf node containing a single integer.
class IntLeaf
  constructor: (@key) ->
    @elements = new Stream(@key)

  size: 1

  get:  (shift, key, data) -> key == @key

  with: (shift, key, leaf) ->
    new BitmapIndexedNode().with(shift, @key, this).with(shift, key, leaf)

  without: (shift, key, data) -> null

  toString: -> "LeafNode(#{@key})"


# The IntSet class.
class IntSet extends Collection
  className: "IntSet"

  # Returns the elements as a stream
  elements: -> @entries

  # Returns true or false depending on whether the given key is an
  # element of this set.
  contains: (key) -> @root.get(0, key) == true

  # Returns a new set with the given keys inserted as elements, or
  # this set if it already contains all those elements.
  with: ->
    newroot = @root
    for key in arguments when util.isKey(key) and not newroot.get(0, key)
      newroot = newroot.with(0, key, new IntLeaf(key))
    if newroot != @root then new IntSet(newroot) else this

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  without: ->
    newroot = @root
    for key in arguments when util.isKey(key) and newroot.get(0, key)
      newroot = newroot.without(0, key)
    if newroot != @root then new IntSet(newroot) else this

IntSet::plus  = IntSet::with
IntSet::minus = IntSet::without


# A leaf node with an integer key and arbitrary value.
class IntLeafWithValue
  constructor: (@key, @value) ->
    @elements = new Stream([@key, @value])

  size: 1

  get:  (shift, key, data) -> @value if key == @key

  with: (shift, key, leaf) ->
    if @key == key
      leaf
    else
      new BitmapIndexedNode().with(shift, @key, this).with(shift, key, leaf)

  without: (shift, key, data) -> null

  toString: -> "LeafNode(#{@key}, #{@value})"


# The IntMap class is essentially a huge sparse array.
class IntMap extends Collection
  className: "IntMap"

  # Returns the (key,value)-pairs as a stream
  items: -> @entries

  # Returns true or false depending on whether the given key is an
  # element of this set.
  get: (key) -> @root.get(0, key)

  # Returns a new set with the given keys inserted as elements, or
  # this set if it already contains all those elements.
  with: ->
    newroot = @root
    for [key, value] in arguments when util.isKey(key)
      unless areEqual(newroot.get(0, key), value)
        newroot = newroot.with(0, key, new IntLeafWithValue(key, value))
    if newroot != @root then new IntMap(newroot) else this

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  without: ->
    newroot = @root
    for key in arguments when util.isKey(key)
      unless typeof newroot.get(0, key) == 'undefined'
        newroot = newroot.without(0, key)
    if newroot != @root then new IntMap(newroot) else this

IntMap::plus  = IntMap::with
IntMap::minus = IntMap::without


# --------------------------------------------------------------------
# Support for collections that use hashing.
# --------------------------------------------------------------------

hashStep = (code, c) -> (code * 37 + c.charCodeAt(0)) % 0x80000000

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

  util.reduce(stringVal, hashStep, 0)

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
    @elements = Stream.fromArray(@bucket)?.flat_map (n) -> n?.elements

  get: (shift, hash, key) ->
    leaf = util.find @bucket, (v) -> areEqual(v.key, key)
    leaf.get(shift, hash, key) if leaf?

  with: (shift, hash, leaf) ->
    if hash != @hash
      new BitmapIndexedNode().with(shift, @hash, this).with(shift, hash, leaf)
    else
      newBucket = this.bucketWithout(leaf.key)
      newBucket.push leaf
      new CollisionNode(hash, newBucket)

  without: (shift, hash, key) ->
    switch @bucket.length
      when 0, 1 then null
      when 2    then util.find @bucket, (v) -> not areEqual(v.key, key)
      else           new CollisionNode(hash, this.bucketWithout(key))

  toString: -> "CollisionNode(#{@bucket.join(", ")})"

  bucketWithout: (key) ->
    item for item in @bucket when not areEqual(item.key, key)


# --------------------------------------------------------------------
# The hash set collection class and its leaf nodes.
# --------------------------------------------------------------------

# A leaf node contains a single key and also caches its hash value.
class HashLeaf
  constructor: (@hash, @key) ->
    @elements = new Stream(@key)

  size: 1

  get:  (shift, hash, key) -> true if areEqual(key, @key)

  with: (shift, hash, leaf) ->
    if hash == @hash
      base = new CollisionNode(hash)
    else
      base = new BitmapIndexedNode()
    base.with(shift, @hash, this).with(shift, hash, leaf)

  without: (shift, hash, key) -> null

  toString: -> "LeafNode(#{@key})"


# The HashSet class provides the public API and serves as a wrapper
# for the various node classes that hold the actual information.
class HashSet extends Collection
  className: "HashSet"

  # Returns the elements as a stream
  elements: -> @entries

  # Returns true or false depending on whether the given key is an
  # element of this set.
  contains: (key) -> @root.get(0, hashCode(key), key) == true

  # Returns a new set with the given keys inserted as elements, or
  # this set if it already contains all those elements.
  with: ->
    newroot = @root
    for key in arguments
      hash = hashCode(key)
      unless newroot.get(0, hash, key)
        newroot = newroot.with(0, hash, new HashLeaf(hash, key))
    if newroot != @root then new HashSet(newroot) else this

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  without: ->
    newroot = @root
    for key in arguments
      hash = hashCode(key)
      newroot = newroot.without(0, hash, key) if newroot.get(0, hash, key)
    if newroot != @root then new HashSet(newroot) else this

HashSet::plus  = HashSet::with
HashSet::minus = HashSet::without


# --------------------------------------------------------------------
# The hash map collection class and its leaf nodes.
# --------------------------------------------------------------------

# A leaf node contains a single key-value pair and also caches the
# hash value for the key.
class HashLeafWithValue
  constructor: (@hash, @key, @value) ->
    @elements = new Stream([@key, @value])

  size: 1

  get:  (shift, hash, key) -> @value if areEqual(key, @key)

  with: (shift, hash, leaf) ->
    if areEqual(@key, leaf.key)
      leaf
    else
      if hash == @hash
        base = new CollisionNode(hash)
      else
        base = new BitmapIndexedNode()
      base.with(shift, @hash, this).with(shift, hash, leaf)

  without: (shift, hash, key) -> null

  toString: -> "LeafNode(#{@key}, #{@value})"


# The HashMap class provides the public API and serves as a wrapper
# for the various node classes that hold the actual information.
class HashMap extends Collection
  className: "HashMap"

  # Returns the (key,value)-pairs as a stream
  items: -> @entries

  # Retrieves the value associated with the given key, or nil if the
  # key is not present.
  get: (key) -> @root.get(0, hashCode(key), key)

  # Returns a new map with the given key-value pair inserted, or
  # this map if it already contains that pair.
  with: ->
    newroot = @root
    for [key, value] in arguments
      hash = hashCode(key)
      unless areEqual(newroot.get(0, hash, key), value)
        newroot = newroot.with(0, hash, new HashLeafWithValue(hash, key, value))
    if newroot != @root then new HashMap(newroot) else this

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  without: ->
    newroot = @root
    for key in arguments
      hash = hashCode(key)
      if typeof(newroot.get(0, hash, key)) != 'undefined'
        newroot = newroot.without(0, hash, key)
    if newroot != @root then new HashMap(newroot) else this

HashMap::plus  = HashMap::with
HashMap::minus = HashMap::without


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.IntSet  = IntSet
  this.pazy.IntMap  = IntMap
  this.pazy.HashMap = HashMap
  this.pazy.HashSet = HashSet
else
  exports.IntSet  = IntSet
  exports.IntMap  = IntMap
  exports.HashMap = HashMap
  exports.HashSet = HashSet
