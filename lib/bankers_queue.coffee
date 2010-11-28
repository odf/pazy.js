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
  constructor: (front, lenf, rear, lenr) ->
    [@front, @lenf, @rear, @lenr] =
      if typeof(front) == 'undefined'
        [null, 0, null, 0]
      else if lenr <= lenf
        [front, lenf, rear, lenr]
      else
        rev = rear.reverse()
        [(if front then front.concat(rev) else rev), lenf + lenr, null, 0]

    @first = @front?.first
    @size  = @lenf + @lenr

  push: (x) ->
    r = @rear
    new Queue(@front, @lenf, new Stream(x, -> r), @lenr + 1)

  rest: -> if @front then new Queue(@front.rest(), @lenf - 1, @rear, @lenr)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.Queue = Queue
else
  exports.Queue = Queue
