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


if typeof(require) == 'function'
  require 'underscore'
  util = require 'hash_util'
else
  util = this.hashUtil


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
  get: (key) -> @root.get(0, util.hash(key), key)

  # Returns a new map with the given key-value pair inserted, or
  # this map if it already contains that pair.
  with: ->
    newroot = @root
    for [key, value] in arguments
      hash = util.hash(key)
      unless util.equal(newroot.get(0, hash, key), value)
        newroot = newroot.with(0, hash, key, value)
    if newroot != @root then new HashMap(newroot) else this

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  without: ->
    newroot = @root
    for key in arguments
      hash = util.hash(key)
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


# The root node for the empty map.
EmptyNode = {
  size:    0

  get:     (shift, hash, key) -> ()

  each:    (func) -> ()

  with:    (shift, hash, key, value) -> new LeafNode(hash, key, value)

  without: (shift, hash, key) -> this

  toString: -> "EmptyNode"
}


# A leaf node contains a single key-value pair and also caches the
# hash value for the key.
class LeafNode
  constructor: (@hash, @key, @value) ->

  size: 1

  each: (func) -> func([@key, @value])

  get:  (shift, hash, key) -> @value if util.equal(key, @key)

  with: (shift, hash, key, value) ->
    if util.equal(key, @key)
      new LeafNode(hash, key, value)
    else if hash == @hash
      new CollisionNode(hash, [[@key, @value], [key, value]])
    else
      BitmapIndexedNode.make(shift, this).with(shift, hash, key, value)

  without: (shift, hash, key) -> null

  toString: -> "LeaveNode(#{@key})"


# A collision node contains several key-value pairs in which all keys
# have a common hash value, which is cached. The key-value pairs are
# stored in an array @bucket.
class CollisionNode
  constructor: (@hash, @bucket) ->
    @size = @bucket.length

  each: (func) ->
    for [key, value] in @bucket
      func(key, value)

  get: (shift, hash, key) ->
    (pair = getEntry(key))? && pair[1]

  with: (shift, hash, key) ->
    if hash != @hash
      BitmapIndexedNode.make(shift, this).with(shift, hash, key, value)
    else
      newBucket = _.without(@bucket, getEntry(key)).concat([[key, value]]))
      new CollisionNode(hash, newBucket)

  without: (shift, hash, key) ->
    newBucket = _.without(@bucket, getEntry(key))
    if newBucket.length < 2
      new LeafNode(hash, _.first(newBucket)...)
    else
      new CollisionNode(hash, newBucket)

  toString: -> "CollisionNode(#{@bucket.join(", ")})"

  getEntry: (key) -> _.detect @bucket, (pair) -> equal(pair[0], key))


# A sparse interior node using a bitmap to indicate which of the
# indices 0..31 are in use.
class BitmapIndexedNode
  constructor: (@bitmap, @array, @size) ->

  each: (func) ->
    for node in @array
      node.each(func)

  get: (shift, hash, key) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, hash, shift)
    (@bitmap & bit) != 0 && @array[i].get(shift + 5, hash, key)

  with: (shift, hash, key, value) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, hash, shift)

    if (@bitmap & bit) == 0
      newNode = new LeafNode(hash, key, value)
      n = util.bitCount(@bitmap)
      if n < 8
        newArray = util.arrayWithInsertion(@array, i, newNode)
        new BitmapIndexedNode(@bitmap | bit, newArray, @size + 1)
      else
        table = new Array(32)
        for m in [0..31]
          b = 1 << m
          table[m] = @array[util.indexForBit(@bitmap, b)] if (@bitmap & b) != 0
        new ArrayNode(table, util.mask(hash, shift), newNode, @size + 1)
    else
      v = @array[i]
      node = v.with(shift + 5, hash, key, value)
      newSize = @size + node.size - v.size
      new BitmapIndexedNode(@bitmap, util.arrayWith(@array, i, node), newSize)

  without: (shift, hash, key) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, hash, shift)

    v = @array[i]
    node = v.without(shift + 5, hash, key)
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

BitmapIndexedNode.make = (shift, node) ->
  new BitmapIndexedNode(1 << util.mask(node.hash, shift), [node], node.size)


# A dense interior node with room for 32 entries.
class ArrayNode
  constructor: (baseTable, i, node, @size) ->
    @table = baseTable[0..]
    @table[i] = node

  each: (func) ->
    for node in @table
      node.each(func) if node?

  get: (shift, hash, key) ->
    i = util.mask(hash, shift)
    @table[i]? && @table[i].get(shift + 5, hash, key)

  with: (shift, hash, key, value) ->
    i = util.mask(hash, shift)

    if @table[i]?
      node = @table[i].with(shift + 5, hash, key, value)
      newSize = @size + node.size - @table[i].size
      new ArrayNode(@table, i, node, newSize)
    else
      new ArrayNode(@table, i, new LeafNode(hash, key, value), @size + 1)

  without: (shift, hash, key) ->
    i = util.mask(hash, shift)

    node = @table[i].without(shift + 5, hash, key)
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

  toString: -> "ArrayNode(#{_.compact(@table).join(", ")})"


# -- exporting

this.HashMap  = HashMap

if typeof(exports) != 'undefined'
  exports.HashMap  = HashMap
