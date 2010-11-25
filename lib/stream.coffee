# A stream (potentially infinite lists with lazy evaluation) class for
# Javascript like all the cool languages have.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)


class Stream
  constructor: (@first, rest) ->
    if typeof(rest) == 'function'
      @rest = -> @force_rest(rest())
    else
      @force_rest(rest)

  force_rest: (val) ->
    @rest = -> val
    val

  take_while: (pred) ->
    if pred(@first)
      new Stream(@first, => @rest().take_while(pred) if @rest())

  take: (n) ->
    if n > 0
      new Stream(@first, => @rest().take(n-1) if @rest())

  drop_while: (pred) ->
    stream = this
    while stream? and pred(stream.first)
      stream = stream.rest()
    stream

  drop: (n) ->
    stream = this
    for i in [1..n]
      break unless stream
      stream = stream.rest()
    stream

  get: (n) -> this.drop(n).first

  map: (func) ->
    new Stream(func(@first), => @rest().map(func) if @rest())

  select: (pred) ->
    if pred(@first)
      new Stream(@first, => @rest().select(pred) if @rest())
    else if @rest()
      @rest().select(pred)

  combine: (other, op) ->
    new Stream(op(this.first, other.first), =>
      this.rest().combine(other.rest(), op) if this.rest() and other.rest())

  plus:  (other) -> @combine(other, (a,b) -> a + b)
  minus: (other) -> @combine(other, (a,b) -> a - b)
  times: (other) -> @combine(other, (a,b) -> a * b)
  by:    (other) -> @combine(other, (a,b) -> a / b)

  accumulate: (start, op) ->
    new_start = op(start, @first)
    new Stream(new_start, => @rest().accumulate(new_start, op) if @rest())

  sums:     -> @accumulate(0, (a,b) -> a + b)
  products: -> @accumulate(1, (a,b) -> a * b)

  merge: (other) -> new Stream(@first, => other.merge(@rest()) if other)

  concatl: (next) ->
    new Stream(@first, => if @rest() then @rest().concatl(next) else next())

  concat: (other) -> @concatl(=> other)

  flatten: -> @first.concatl(=> @rest().flatten() if @rest())

  flat_map: (func) -> @map(func).flatten()

  # The following functions force evaluation of the stream

  each: (func) ->
    stream = this
    while stream?
      func(stream.first)
      stream = stream.rest()
    null

  size: ->
    count = 0
    this.each -> count += 1
    count

  last: ->
    stream = this
    while stream.rest()
      stream = stream.rest()
    stream.first

  toArray: ->
    buffer = []
    this.each (x) -> buffer.push(x)
    buffer

  toString: -> @toArray().join(', ')

Stream.iterate = (start, step) ->
  new Stream(start, -> Stream.iterate(step(start), step))

Stream.from = (start) -> new Stream(start, -> Stream.from(start + 1))


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

this.Stream = Stream

if typeof(exports) != 'undefined'
  exports.Stream = Stream
