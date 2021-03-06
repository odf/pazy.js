# --------------------------------------------------------------------
# An implementation of Chris Okasaki's functional real-time
# double-ended queue with constant amortized persistent execution time
# per operation.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  { seq } = require('sequence')
else
  { seq } = this.pazy


class Dequeue
  c = 2

  constructor: -> [@front, @lf, @rear, @lr] = [null, 0, null, 0]

  create = (front, lf, rear, lr) ->
    deq = new Dequeue()
    if lf > c * lr + 1
      deq.lf = i = (lf + lr) >> 1
      deq.lr     = lf + lr - i
      deq.front  = front.take i
      deq.rear   = seq.concat rear, front.drop(i).reverse()
    else if lr > c * lf + 1
      deq.lr = i = (lf + lr) >> 1
      deq.lf     = lf + lr - i
      deq.rear   = rear.take i
      deq.front  = seq.concat front, rear.drop(i).reverse()
    else
      deq.lf    = lf
      deq.lr    = lr
      deq.front = front
      deq.rear  = rear
    deq

  size: -> @lf + @lr

  after: (x) ->
    if typeof x == 'undefined'
      this
    else
      create seq.conj(x, (=> @front)), @lf + 1, @rear, @lr

  before: (x) ->
    if typeof x == 'undefined'
      this
    else
      create @front, @lf, seq.conj(x, (=> @rear)), @lr + 1

  first: ->
    if @front then @front.first() else if @rear then @rear.first()

  last: ->
    if @rear then @rear.first() else if @front then @front.first()

  rest: ->
    if @front?
      create @front.rest(), @lf - 1, @rear, @lr
    else if @rest
      new Dequeue()

  init: ->
    if @rear?
      create @front, @lf, @rear.rest(), @lr - 1
    else if @front
      new Dequeue()


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports = module?.exports or this.pazy ?= {}
exports.Dequeue = Dequeue
