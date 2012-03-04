# --------------------------------------------------------------------
# Chris Okasaki's skew binary random access list, a functional data
# structure with worst case persistent execution time of O(1) for
# operations on the head and O(log n) for random access operations.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  { bounce } = require('functional')
  { seq }        = require('sequence')
else
  { bounce, seq } = this.pazy

list = (car, cdr) ->
  first: -> car
  rest:  -> cdr


class RandomAccessList
  constructor: (@trees = null) ->

  @cached: (name, code) ->
    @::[name] = -> val = code.apply(this); (@[name] = -> val)()

  @cached 'size', ->
    if @trees then seq.reduce(@trees, 0, (s, [w,t]) -> s + w) else 0

  half = (w) -> Math.floor w/2

  cons: (x) ->
    [w, t, r] =
      if @trees?.rest() and @trees.first()[0] == @trees.rest().first()[0]
        [[w1, t1], [w2, t2]] = [@trees.first(), @trees.rest().first()]
        [1+w1+w2, [x,t1,t2], @trees.rest().rest()]
      else
        [1, [x], @trees]
    new RandomAccessList(list([w, t], r))

  first: -> @trees.first()[1][0] if @trees

  rest: ->
    if @trees
      [w, [x, t1, t2]] = @trees.first()
      new RandomAccessList(
        if w == 1
          @trees.rest()
        else
          list([half(w), t1], list([half(w), t2], @trees.rest()))
      )

  lookup: (i) ->
    lookupTree = (w, [x, t1, t2], i) ->
      if i == 0
        x
      else if w > 1
        if i-1 < half(w)
          -> lookupTree(half(w), t1, i-1)
        else
          -> lookupTree(half(w), t2, i-1-half(w))

    step = (trees, i) ->
      if trees
        [w, t] = trees.first()
        if i < w
          bounce lookupTree(w, t, i)
        else
          -> step(trees.rest(), i-w)

    bounce step(@trees, i) if i >= 0

  update: (i, y) ->
    zipUp = (r, s) ->
      if r
        [x, t1, t2] = r.first()
        if t1
          -> zipUp(r.rest(), [x, t1, s])
        else
          -> zipUp(r.rest(), [x, s, t2])
      else
        s

    updateTree = (r, w, [x, t1, t2], i) ->
      if i == 0
        bounce zipUp(r, if w == 1 then [y] else [y, t1, t2])
      else
        wh = half(w)
        if i-1 < wh
          -> updateTree(list([x, null, t2], r), wh, t1, i-1)
        else
          -> updateTree(list([x, t1, null], r), wh, t2, i-1-wh)

    step = (r, s, i) =>
      if s
        [w, t] = s.first()
        if i < w
          newTree = bounce updateTree(null, w, t, i)
          seq.reverse(list([w, newTree], r)).concat(s.rest()).forced()
        else
          -> step(list(s.first(), r), s.rest(), i - w)
      else
        throw new Error("index too large")

    if i >= 0
      new RandomAccessList(bounce step(null, @trees, i))
    else
      throw new Error("negative index")


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.RandomAccessList = RandomAccessList
