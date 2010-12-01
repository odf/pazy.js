# --------------------------------------------------------------------
# An implementation of Chris Okasaki's shared bottom-up-merge
# sortable, a functional data structure with amortized persistent
# execution time O(log n) per operation for adding an element and O(n)
# for extracting a sorted result.
#
# The recursive helper functions merge(), addSeg() and mergeAll() from
# the original algorithm have been replaced with iterative
# versions to avoid stack overflow.
#
# A simple nested-pairs list of arrays is used instead of a list of
# lists to represent the data .
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


class Sortable
  constructor: (@less, size, segments) ->
    [@size, @_segs] = if size?
      [size, => val = segments(); (@_segs = -> val)()]
    else
      [0, -> null]

  plus: ->
    s = this
    for x in arguments
      t = s
      s = new Sortable(s.less, s.size + 1, -> newSegments(x, t))
    s

  sort: ->
    [buf, segs] = [[], @_segs()]
    while segs?
      [buf, segs] = [merge(@less, buf, segs[0]), segs[1]]
    buf

  merge = (less, xs, ys) ->
    [buf, ix, iy, lx, ly] = [[], 0, 0, xs.length, ys.length]
    while ix < lx and iy < ly
      if less(xs[ix], ys[iy]) then buf.push(xs[ix++]) else buf.push(ys[iy++])
    buf.concat(xs[ix..], ys[iy..])

  newSegments = (x, t) ->
    [seg, less, segs, bits] = [[x], t.less, t._segs(), t.size]
    while bits % 2 > 0
      [seg, segs, bits] = [merge(less, seg, segs[0]), segs[1], bits >> 1]
    [seg, segs]


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.Sortable = Sortable
else
  exports.Sortable = Sortable
