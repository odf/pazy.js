# --------------------------------------------------------------------
# An implementation of Chris Okasaki's shared bottom-up-merge
# sortable.
#
# The recursive helper functions merge(), addSeg() and mergeAll() from
# the original algorithm have been replaced with iterative
# implementations to avoid stack overflow, and the new code for
# mergeAll() then inserted into sort().
#
# A list of arrays is used to represent the data instead of a list of
# lists.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  suspend = require('lazy').suspend
else
  suspend = pazy.suspend


merge = (less, xs, ys) ->
  [buf, ix, iy, lx, ly] = [[], 0, 0, xs.length, ys.length]

  while ix < lx and iy < ly
    if less(xs[ix], ys[iy])
      buf.push(xs[ix])
      ix += 1
    else
      buf.push(ys[iy])
      iy += 1

  buf.concat(xs[ix..], ys[iy..])


addSegment = (less, seg, segs, bits) ->
  while bits % 2 > 0
    [seg, segs, bits] = [merge(less, seg, segs[0]), segs[1], bits >> 1]
  [seg, segs]


class Sortable
  constructor: (@less, size, segments) ->
    [@size, @_segs] = if size? then [size, segments] else [0, -> null]

  plus: (x) ->
    new Sortable(@less, @size + 1,
                 suspend(=> addSegment(@less, [x], @_segs(), @size)))

  sort: ->
    [buf, segs] = [[], @_segs()]
    while segs?
      [buf, segs] = [merge(@less, buf, segs[0]), segs[1]]
    buf


segsToString = (segs) ->
  buf = []
  while segs?
    buf.push(segs[0])
    segs = segs[1]
  ("[#{a}]" for a in buf).join(", ")

puts = (s) -> print s + '\n'

a = new Sortable((a, b) -> a < b)
b = a.plus(3).plus(4).plus(2).plus(5).plus(1).plus(7).plus(6)

puts "b.size    = #{b.size}"
puts "b._segs() = #{segsToString(b._segs())}"
puts "b.sort()  = #{b.sort()}"
