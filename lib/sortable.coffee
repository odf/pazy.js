# --------------------------------------------------------------------
# An implementation of Chris Okasaki's shared bottom-up-merge
# sortable, a functional data structure with amortized persistent
# execution time O(log n) per operation for adding an element and O(n)
# for extracting a sorted result.
#
# The recursive helper functions merge(), addSeg() and mergeAll() from
# the original algorithm have been replaced with iterative
# implementations to avoid stack overflow, and the new code for
# mergeAll() then inserted into sort().
#
# A simple nested-pairs list of arrays is used instead of a list of
# lists to represent the data .
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


merge = (less, xs, ys) ->
  [buf, ix, iy, lx, ly] = [[], 0, 0, xs.length, ys.length]
  while ix < lx and iy < ly
    if less(xs[ix], ys[iy]) then buf.push(xs[ix++]) else buf.push(ys[iy++])
  buf.concat(xs[ix..], ys[iy..])


addSegment = (less, seg, segs, bits) ->
  while bits % 2 > 0
    [seg, segs, bits] = [merge(less, seg, segs[0]), segs[1], bits >> 1]
  [seg, segs]


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
      s = new Sortable(s.less, s.size + 1,
                       -> addSegment(t.less, [x], t._segs(), t.size))
    s

  sort: ->
    [buf, segs] = [[], @_segs()]
    while segs?
      [buf, segs] = [merge(@less, buf, segs[0]), segs[1]]
    buf


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.Sortable = Sortable
else
  exports.Sortable = Sortable
