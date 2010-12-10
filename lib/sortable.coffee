# --------------------------------------------------------------------
# An implementation of Chris Okasaki's shared bottom-up-merge
# sortable, a functional data structure with amortized persistent
# execution time O(log n) per operation for adding an element and O(n)
# for extracting a sorted result.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require('trampoline')
  { List }           = require('list')
else
  { recur, resolve, List } = this.pazy


class Sortable
  constructor: (@less, size, segments) ->
    [@_size, @_segs] = if size?
      [size, => val = segments(); (@_segs = -> val)()]
    else
      [0, -> null]

  size: -> @_size

  plus: ->
    less = @less

    addSeg = (seg, segs, bits) ->
      if bits % 2 > 0
        recur -> addSeg(merge(less, seg, segs.first()), segs.rest(), bits >> 1)
      else
        new List(seg, segs)

    step = (s, args) ->
      if args.length > 0
        [x, a...] = args
        newSegs = -> resolve addSeg(new List(x), s._segs(), s.size())
        recur -> step(new Sortable(less, s.size() + 1, newSegs), a)
      else
        s

    resolve step(this, arguments)

  sort: ->
    less = @less
    step = (buf, segs) ->
      if segs?
        recur -> step(merge(less, buf, segs.first()), segs.rest())
      else
        buf
    resolve step(null, @_segs())

  merge = (less, xs, ys) ->
    step = (r, xs, ys) ->
      if xs and (not ys or less(xs.first(), ys.first()))
        recur -> step(new List(xs.first(), r), xs.rest(), ys)
      else if ys
        recur -> step(new List(ys.first(), r), xs, ys.rest())
      else
        r
    (resolve step(null, xs, ys))?.reverse()


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sortable = Sortable
