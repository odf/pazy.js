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
  { Sequence }       = require('sequence')
else
  { recur, resolve, Sequence } = this.pazy

class List
  constructor: (car, cdr) ->
    @[0] = car
    @[1] = cdr

  first: -> @[0]
  rest: -> @[1]


class RandomAccessList
  constructor: (@trees = null) ->

  @cached: (name, code) ->
    @::[name] = -> val = code.apply(this); (@[name] = -> val)()

  @cached 'size', ->
    if @trees then Sequence.reduce(@trees, 0, (s, [w,t]) -> s + w) else 0

  half = (w) -> Math.floor w/2

  cons: (x) ->
    [w, t, r] =
      if @trees?.rest() and @trees.first()[0] == @trees.rest().first()[0]
        [[w1, t1], [w2, t2]] = [@trees.first(), @trees.rest().first()]
        [1+w1+w2, [x,t1,t2], @trees.rest().rest()]
      else
        [1, [x], @trees]
    new RandomAccessList(new List([w, t], r))

  first: -> @trees.first()[1][0] if @trees

  rest: ->
    if @trees
      [w, [x, t1, t2]] = @trees.first()
      new RandomAccessList(
        if w == 1
          @trees.rest()
        else
          new List([half(w), t1], new List([half(w), t2], @trees.rest()))
      )

  lookup: (i) ->
    lookupTree = (w, [x, t1, t2], i) ->
      if i == 0
        x
      else if w > 1
        if i-1 < half(w)
          recur -> lookupTree(half(w), t1, i-1)
        else
          recur -> lookupTree(half(w), t2, i-1-half(w))

    step = (trees, i) ->
      if trees
        [w, t] = trees.first()
        if i < w
          resolve lookupTree(w, t, i)
        else
          recur -> step(trees.rest(), i-w)

    resolve step(@trees, i) if i >= 0

  update: (i, y) ->
    zipUp = (r, s) ->
      if r
        [x, t1, t2] = r.first()
        if t1
          recur -> zipUp(r.rest(), [x, t1, s])
        else
          recur -> zipUp(r.rest(), [x, s, t2])
      else
        s

    updateTree = (r, w, [x, t1, t2], i) ->
      if i == 0
        resolve zipUp(r, if w == 1 then [y] else [y, t1, t2])
      else
        wh = half(w)
        if i-1 < wh
          recur -> updateTree(new List([x, null, t2], r), wh, t1, i-1)
        else
          recur -> updateTree(new List([x, t1, null], r), wh, t2, i-1-wh)

    step = (r, s, i) =>
      if s
        [w, t] = s.first()
        if i < w
          newTree = resolve updateTree(null, w, t, i)
          Sequence.reverse(new List([w, newTree], r)).concat(s.rest()).forced()
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
