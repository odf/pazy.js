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
    step = (trees, i) =>
      if trees
        [w, t] = trees.first()
        if i < w then @lookupTree(w, t, i) else recur -> step(trees.rest(), i-w)
    resolve step(@trees, i) if i >= 0

  lookupTree: (w, t, i) ->
    step = (w, [x, t1, t2], i) ->
      if i == 0
        x
      else if w > 1
        wh = Math.floor w/2
        if i-1 < wh
          recur -> step(wh, t1, i-1)
        else
          recur -> step(wh, t2, i-1-wh)
    resolve step(w, t, i)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.RandomAccessList = RandomAccessList
