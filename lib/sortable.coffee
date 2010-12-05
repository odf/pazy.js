# --------------------------------------------------------------------
# An implementation of Chris Okasaki's shared bottom-up-merge
# sortable, a functional data structure with amortized persistent
# execution time O(log n) per operation for adding an element and O(n)
# for extracting a sorted result.
#
# A simple nested-pairs list of arrays is used instead of a list of
# lists to represent the data. As a consequence, the recursive helper
# function merge() has been replaced by an iterative version for
# efficiency reasons.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  pazy = require('trampoline')

recur = pazy.recur
resolve = pazy.resolve


class Sortable
  constructor: (@less, size, segments) ->
    [@size, @_segs] = if size?
      [size, => val = segments(); (@_segs = -> val)()]
    else
      [0, -> null]

  plus: ->
    less = @less

    addSeg = (seg, segs, bits) ->
      if bits % 2 > 0
        recur -> addSeg(merge(less, seg, segs[0]), segs[1], bits >> 1)
      else
        [seg, segs]

    step = (s, args) ->
      if args.length > 0
        [x, a...] = args
        newSegs = -> resolve addSeg([x], s._segs(), s.size)
        recur -> step(new Sortable(less, s.size + 1, newSegs), a)
      else
        s

    resolve step(this, arguments)

  sort: ->
    less = @less
    step = (buf, segs) ->
      if segs? then recur -> step(merge(less, buf, segs[0]), segs[1]) else buf
    resolve step([], @_segs())

  merge = (less, xs, ys) ->
    [buf, ix, iy, lx, ly] = [[], 0, 0, xs.length, ys.length]
    while ix < lx and iy < ly
      if less(xs[ix], ys[iy]) then buf.push(xs[ix++]) else buf.push(ys[iy++])
    buf.concat(xs[ix..], ys[iy..])


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.Sortable = Sortable
else
  exports.Sortable = Sortable
