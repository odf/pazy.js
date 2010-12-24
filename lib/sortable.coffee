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
  { recur, resolve } = require('functional')
  { Sequence }       = require('sequence')
else
  { recur, resolve, Sequence } = this.pazy


class Sortable
  constructor: (@less, @size__ = 0, @segs = null) ->

  size: -> @size__

  plus: ->
    less = @less

    addSeg = (seg, segs, bits) ->
      if bits % 2 > 0
        recur -> addSeg(merge(less, seg, segs.first()), segs.rest(), bits >> 1)
      else
        Sequence.conj seg, (-> segs), 'forced'

    if arguments.length > 0
      Sequence.reduce arguments, this, (s, x) ->
        newSegs = resolve addSeg(Sequence.conj(x), s.segs, s.size())
        new Sortable(less, s.size() + 1, newSegs)
    else
      this

  sort: -> @segs.reduce(null, (r, s) => merge(@less, r, s))

  merge = (less, xs, ys) ->
    if xs and (not ys or less(xs.first(), ys.first()))
      Sequence.conj xs.first(), (-> merge(less, xs.rest(), ys)), 'stored'
    else if ys
      Sequence.conj ys.first(), (-> merge(less, xs, ys.rest())), 'stored'


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sortable = Sortable
