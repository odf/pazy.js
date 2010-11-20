# --------------------------------------------------------------------
# A map class based on Rich Hickey's persistent hash trie
# implementation from Clojure (http://clojure.org). Originally
# presented as a mutable data structure in a paper by Phil Bagwell.
#
# To simplify the logic, the HashMap class only calls with() or
# without() on the root node if a change needs to be made. Thus
# there is no longer any special code in the node classes for
# optimizing idempotent operations.
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

require 'underscore' if typeof require == 'function'


# A collection of utility functions used by interior nodes.
util = {
  arrayWith: (a, i, x) -> a[...i].concat([x], a[i+1..])

  arrayWithInsertion: (a, i, x) -> a[...i].concat([x], a[i..])

  arrayWithout: (a, i) -> a[...i].concat(a[i+1..])


  mask: (hash, shift) -> (hash >> shift) & 0x1f

  bitCount: (n) ->
    n -= (n >> 1) & 0x55555555
    n = (n & 0x33333333) + ((n >> 2) & 0x33333333)
    n = (n & 0x0f0f0f0f) + ((n >> 4) & 0x0f0f0f0f)
    n += n >> 8
    (n + (n >> 16)) & 0x3f

  indexForBit: (bitmap, bit) -> util.bitCount(bitmap & (bit - 1))

  bitPosAndIndex: (bitmap, hash, shift) ->
    bit = 1 << util.mask(hash, shift)
    [bit, util.indexForBit(bitmap, bit)]
}


# A node with no entries. We need only one of those.
EmptyNode = {
  size:    0

  get:     (shift, hash, key) -> ()

  each:    (func) -> ()

  with:    (shift, hash, leaf) -> leaf

  without: (shift, hash, key) -> this

  toString: -> "EmptyNode"
}


# A sparse interior node using a bitmap to indicate which of the
# indices 0..31 are in use.
class BitmapIndexedNode
  constructor: (@bitmap, @array, @size) ->
    unless @bitmap?
      @bitmap = 0
      @array  = []
      @size   = 0

  each: (func) ->
    for node in @array
      node.each(func)

  get: (shift, key, data) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)
    @array[i].get(shift + 5, key, data) if (@bitmap & bit) != 0

  with: (shift, key, leaf) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)

    if (@bitmap & bit) == 0
      n = util.bitCount(@bitmap)
      if n < 8
        newArray = util.arrayWithInsertion(@array, i, leaf)
        new BitmapIndexedNode(@bitmap | bit, newArray, @size + 1)
      else
        table = new Array(32)
        for m in [0..31]
          b = 1 << m
          table[m] = @array[util.indexForBit(@bitmap, b)] if (@bitmap & b) != 0
        new ArrayNode(table, util.mask(key, shift), leaf, @size + 1)
    else
      v = @array[i]
      node = v.with(shift + 5, key, leaf)
      newSize = @size + node.size - v.size
      new BitmapIndexedNode(@bitmap, util.arrayWith(@array, i, node), newSize)

  without: (shift, key, data) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, key, shift)

    v = @array[i]
    node = v.without(shift + 5, key, data)
    if node?
      newSize = @size + node.size - v.size
      new BitmapIndexedNode(@bitmap, util.arrayWith(@array, i, node), newSize)
    else
      newBitmap = @bitmap ^ bit
      newArray  = util.arrayWithout(@array, i)
      switch util.bitCount(newBitmap)
        when 0 then null
        when 1 then newArray[0]
        else   new BitmapIndexedNode(newBitmap, newArray, @size - 1)

  toString: -> "BitmapIndexedNode(#{@array.join(", ")})"


# A dense interior node with room for 32 entries.
class ArrayNode
  constructor: (baseTable, i, node, @size) ->
    @table = baseTable[0..]
    @table[i] = node

  each: (func) ->
    for node in @table
      node.each(func) if node?

  get: (shift, key, data) ->
    i = util.mask(key, shift)
    @table[i].get(shift + 5, key, data) if @table[i]?

  with: (shift, key, leaf) ->
    i = util.mask(key, shift)

    if @table[i]?
      node = @table[i].with(shift + 5, key, leaf)
      newSize = @size + node.size - @table[i].size
      new ArrayNode(@table, i, node, newSize)
    else
      new ArrayNode(@table, i, leaf, @size + 1)

  without: (shift, key, data) ->
    i = util.mask(key, shift)

    node = @table[i].without(shift + 5, key, data)
    if node?
      new ArrayNode(@table, i, node, @size - 1)
    else
      remaining = j for j in [1...@table.length] when j != i and @table[j]
      if remaining.length <= 4
        bitmap = _.reduce(remaining, ((b, j) -> b | (1 << j)), 0)
        array  = @table[j] for j in remaining
        new BitmapIndexedNode(bitmap, array, @size - 1)
      else
        new ArrayNode(@table, i, null, @size - 1)

  toString: -> "ArrayNode(#{(x for x in @table when x?).join(", ")})"


hashCode = (obj) ->
  if obj? and typeof(obj.hashCode) == "function"
    code = obj.hashCode()
    if typeof(code) == "number" and code > 0 and code % 1 == 0
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
        Object.prototype.toString.call(obj)

  _.reduce(stringVal, ((code, c) -> code * 37 + c.charCodeAt(0)), 0)

areEqual = (obj1, obj2) ->
  if obj1? and typeof(obj1.equals) == "function"
    obj1.equals(obj2)
  else if obj2? and typeof(obj2.equals) == "function"
    obj2.equals(obj1)
  else
    obj1 == obj2


# The HashMap class provides the public API and serves as a wrapper
# for the various node classes that hold the actual information.
class HashMap
  # The constructor creates an empty HashMap.
  constructor: (@root) ->
    @root ?= EmptyNode
    @size = @root.size
    @isEmpty = @size == 0

  # If called with a block, iterates over the items (key-value pairs)
  # in this map; otherwise, returns this map (this mimics Ruby
  # enumerables).
  each: (func) -> if func? then @root.each(func) else this

  # Returns the items in this map as an array.
  toArray: ->
    tmp = []
    this.each (key) -> tmp.push(key)
    tmp

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
        newroot = newroot.with(0, hash, new LeafNode(hash, key, value))
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

  # Returns a map with the values transformed by to the function
  # given.
  apply: (func) ->
    h = new HashMap()
    this.each (key) -> h = h.with(func(key))
    h

  # Returns a string representation of this set.
  toString: -> "HashMap(#{@root})"

HashMap.prototype.plus  = HashMap.prototype.with
HashMap.prototype.minus = HashMap.prototype.without


# A leaf node contains a single key-value pair and also caches the
# hash value for the key.
class LeafNode
  constructor: (@hash, @key, @value) ->

  size: 1

  each: (func) -> func([@key, @value])

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


# A collision node contains several leaf nodes, stored in an array
# @bucket, in which all keys share a common hash value.
class CollisionNode
  constructor: (@hash, @bucket) ->
    @bucket = [] unless @bucket?
    @size = @bucket.length

  each: (func) ->
    for node in @bucket
      node.each(func)

  get: (shift, hash, key) ->
    leaf = _.detect @bucket, (v) -> areEqual(v.key, key)
    leaf.get(shift, hash, key) if leaf?

  with: (shift, hash, leaf) ->
    if hash != @hash
      new BitmapIndexedNode().with(shift, @hash, this).with(shift, hash, leaf)
    else
      new CollisionNode(hash, this.bucketWithout(leaf.key).concat([leaf]))

  without: (shift, hash, key) ->
    switch @bucket.length
      when 0, 1 then null
      when 2    then _.detect @bucket, (v) -> not areEqual(v.key, key)
      else           new CollisionNode(hash, this.bucketWithout(key))

  toString: -> "CollisionNode(#{@bucket.join(", ")})"

  bucketWithout: (key) ->
    item for item in @bucket when not areEqual(item.key, key)


# -- exporting

this.HashMap  = HashMap

if typeof(exports) != 'undefined'
  exports.HashMap  = HashMap
