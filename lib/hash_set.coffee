# --------------------------------------------------------------------
# A set class based on Rich Hickey's persistent hash trie
# implementation from Clojure (http://clojure.org). Originally
# presented as a mutable data structure in a paper by Phil Bagwell.
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


# The HashSet class provides the public API and serves as a wrapper
# for the various node classes that hold the actual information.
class HashSet
  # The constructor creates an empty HashSet.
  constructor: (@root) ->
    @root ?= EmptyNode
    @size = @root.size
    @isEmpty = @size == 0

  # If called with a block, iterates over the elements in this set;
  # otherwise, returns this set (this mimics Ruby enumerables).
  each: (func) -> if func? then @root.each(func) else this

  # Returns the elements in this set as an array.
  toArray: ->
    tmp = []
    this.each (key) -> tmp.push(key)
    tmp

  # Returns true or false depending on whether the given key is an
  # element of this set.
  get: (key) -> @root.get(0, util.hash(key), key)

  # Returns a new set with the given keys inserted as elements, or
  # this set if it already contains all those elements.
  with: ->
    newroot = @root
    for key in arguments
      hash = util.hash(key)
      newroot = newroot.with(0, hash, key) unless newroot.get(0, hash, key)
    if newroot != @root then new HashSet(newroot) else this

  # Returns a new set with the given keys removed, or this set if it
  # does not contain any of them.
  without: ->
    newroot = @root
    for key in arguments
      hash = util.hash(key)
      newroot = newroot.without(0, hash, key) if newroot.get(0, hash, key)
    if newroot != @root then new HashSet(newroot) else this

  # Returns a string representation of this set.
  toString: -> "HashSet(#{@root})"

HashSet.prototype.plus  = HashSet.prototype.with
HashSet.prototype.minus = HashSet.prototype.without


# The root node for the empty set.
EmptyNode = {
  size:    0

  get:     (shift, hash, key) -> false

  each:    (func) -> ()

  with:    (shift, hash, key) -> new LeafNode(hash, key)

  without: (shift, hash, key) -> this

  toString: -> "EmptyNode"
}


# A leaf node contains a single key and also caches its hash value.
class LeafNode
  constructor: (@hash, @key) ->

  size: 1

  each: (func) -> func(@key)

  get:  (shift, hash, key) -> util.equal(key, @key)

  with: (shift, hash, key) ->
    if hash == @hash
      new CollisionNode(hash, [@key, key])
    else
      BitmapIndexedNode.make(shift, this).with(shift, hash, key)

  without: (shift, hash, key) -> null

  toString: -> "LeaveNode(#{@key})"


# A collision node contains several keys with a common hash value,
# which is cached. The keys are stored in the array @bucket.
class CollisionNode
  constructor: (@hash, @bucket) ->
    @size = @bucket.length

  each: (func) ->
    for key in @bucket
      func(key)

  get: (shift, hash, key) -> _.contains(@bucket, key)

  with: (shift, hash, key) ->
    if hash != @hash
      BitmapIndexedNode.make(shift, this).with(shift, hash, key)
    else
      new CollisionNode(hash, _.without(@bucket, key).concat([key]))

  without: (shift, hash, key) ->
    newbucket = _.without(@bucket, key)
    if newbucket.length < 2
      new LeafNode(hash, _.first(newbucket))
    else
      new CollisionNode(hash, newbucket)

  toString: -> "CollisionNode(#{@bucket.join(", ")})"


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

  with: (shift, hash, key) ->
    [bit, i] = util.bitPosAndIndex(@bitmap, hash, shift)

    if (@bitmap & bit) == 0
      newNode = new LeafNode(hash, key)
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
      node = v.with(shift + 5, hash, key)
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

  with: (shift, hash, key) ->
    i = util.mask(hash, shift)

    if @table[i]?
      node = @table[i].with(shift + 5, hash, key)
      newSize = @size + node.size - @table[i].size
      new ArrayNode(@table, i, node, newSize)
    else
      new ArrayNode(@table, i, new LeafNode(hash, key), @size + 1)

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

this.HashSet = HashSet

if typeof(exports) != 'undefined'
  exports.HashSet = HashSet
