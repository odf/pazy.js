# --------------------------------------------------------------------
# An implementation of Chris Okasaki's banker's queue, a purely
# functional queue with constant amortized persistent execution time
# per operation.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  Stream = require('stream').Stream
else
  Stream = pazy.Stream


class Queue
  constructor: (front, len_f, rear, len_r) ->
    [@front, @len_f, @rear, @len_r] =
      if typeof(front) == 'undefined'
        [null, 0, null, 0]
      else if len_r <= len_f
        [front, len_f, rear, len_r]
      else
        rev = rear.reverse()
        [(if front then front.concat(rev) else rev), len_f + len_r, null, 0]

    @first = @front?.first
    @size  = @len_f + @len_r

  push: (x) ->
    r = @rear
    new Queue(@front, @len_f, new Stream(x, -> r), @len_r + 1)

  rest: -> if @front then new Queue(@front.rest(), @len_f - 1, @rear, @len_r)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.Queue = Queue
else
  exports.Queue = Queue
