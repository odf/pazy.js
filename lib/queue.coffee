# --------------------------------------------------------------------
# An implementation of Chris Okasaki's functional real-time queue with
# constant worst-case persistent execution time per operation.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Sequence } = require('sequence')
else
  { Sequence } = this.pazy


class Queue
  constructor: (f, r, s) ->
    if s
      [@front, @rear, @schedule] = [f, r, s.rest()]
    else if f or r
      @front = @schedule = rotate(f, r, null)
      @rear = null
    else
      @front = @rear = @schedule = null

  rotate = (f, r, a) ->
    a1 = Sequence.conj r.first(), (-> a), 'stored'
    if f
      Sequence.conj f.first(), (-> rotate f.rest(), r.rest(), a1), 'stored'
    else
      a1

  push: (x) ->
    new Queue(@front, Sequence.conj(x, (=> @rear), 'stored'), @schedule)

  first: -> @front?.first()

  rest: -> if @front then new Queue(@front.rest(), @rear, @schedule)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Queue = Queue
