# --------------------------------------------------------------------
# An implementation of Chris Okasaki's functional real-time queue with
# constant worst-case persistent execution time per operation.
#
# TODO: The scheduling is missing, so O(1) bounds don't yet hold.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Stream } = require('stream')
  { List }   = require('list')
else
  { Stream, List } = this.pazy


class Queue
  constructor: (front, len_f, rear, len_r) ->
    [@front, @len_f, @rear, @len_r] =
      if typeof(front) == 'undefined'
        [null, 0, null, 0]
      else if len_r <= len_f
        [front, len_f, rear, len_r]
      else
        [rotate(front, rear, null), len_f + len_r, null, 0]

    @first = -> @front?.first()
    @size  = -> @len_f + @len_r

  rotate = (f, r, a) ->
    if f
      new Stream(f.first(),
                 -> rotate(f.rest(), r.rest(), new Stream(r.first(), -> a)))
    else
      new Stream(r.first(), -> a)

  push: (x) -> new Queue(@front, @len_f, new List(x, @rear), @len_r + 1)

  rest: -> if @front then new Queue(@front.rest(), @len_f - 1, @rear, @len_r)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Queue = Queue
