# --------------------------------------------------------------------
# Chris Okasaki's skew binary random access list, a functional data
# structure with worst case persistent execution time of O(1) for
# operations on the head and O(log n) for random access operations.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require('trampoline')
  { List }           = require('list')
else
  { recur, resolve, List } = this.pazy


class RandomAccessList
  constructor: (@trees = null) ->

  @cached: (name, code) ->
    @::[name] = -> val = code.apply(this); (@[name] = -> val)()

  @cached 'size', ->
    if @trees then @trees.reduce(0, (s, [w,t]) -> s + w) else 0

  cons: (x) ->
    new RandomAccessList(
      if @trees?.rest()
        [[w1, t1], [w2, t2]] = [@trees.first(), @trees.rest().first()]
        if w1 == w2
          new List([1+w1+w2, [x,t1,t2]], @trees.rest().rest())
        else
          new List([1, [x]], @trees)
      else
        new List([1, [x]], @trees)
    )

  first: -> @trees.first()[1][0] if @trees

  rest: ->
    if @trees
      [w,[x,t1,t2]] = @trees.first()
      new RandomAccessList(
        if w == 1
          @trees.rest()
        else
          wh = Math.floor w/2
          new List([wh, t1], new List([wh, t2], @trees.rest()))
      )

  lookup: (i) ->
    lookupTree = (w, [x, t1, t2], i) ->
      if i == 0
        x
      else if w > 1
        wh = Math.floor w/2
        if i-1 < wh
          recur -> lookupTree(wh, t1, i-1)
        else
          recur -> lookupTree(wh, t2, i-1-wh)

    step = (trees, i) ->
      if trees
        [w, t] = trees.first()
        if i < w
          resolve lookupTree(w, t, i)
        else
          recur -> step(trees.rest(), i-w)

    resolve step(@trees, i) if i >= 0

  update: (i, y) ->
    updateTree = (w, [x, t1, t2], i) ->
      if i == 0
        if w == 1 then [y] else [y, t1, t2]
      else
        wh = Math.floor w/2
        if i-1 < wh
          [x, updateTree(wh, t1, i-1), t2]
        else
          [x, t1, updateTree(wh, t2, i-1-wh)]

    step = (r, s, i) =>
      if s
        [w, t] = s.first()
        if i < w
          newTree = updateTree(w, t, i)
          new List([w, newTree], r).reverse_concat(s.rest())
        else
          recur -> step(new List(s.first(), r), s.rest(), i - w)
      else
        throw new Error("index too large")

    if i >= 0
      new RandomAccessList(resolve step(null, @trees, i))
    else
      throw new Error("negative index")


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.RandomAccessList = RandomAccessList
