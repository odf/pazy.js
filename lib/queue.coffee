# --------------------------------------------------------------------
# An implementation of Chris Okasaki's functional real-time queue with
# constant worst-case persistent execution time per operation.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  { seq } = require('sequence')
else
  { seq } = this.pazy


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
    a1 = seq.conj r.first(), (-> a)
    if f
      seq.conj f.first(), (-> rotate f.rest(), r.rest(), a1)
    else
      a1

  push: (x) ->
    new Queue(@front, seq.conj(x, (=> @rear)), @schedule)

  first: -> @front?.first()

  rest: -> new Queue(@front?.rest(), @rear, @schedule)

  toSeq: -> seq.concat @front, seq.reverse @rear


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports = module?.exports or this.pazy ?= {}
exports.Queue = Queue
