# --------------------------------------------------------------------
# A stream class for Javascript like all the cool languages have.
#
# Streams are essentially Lisp-ish lists with deferred evaluation on
# the tail (or cdr) part. This means that (conceptually) infinite
# streams can easily be constructed and manipulated and only as much
# of the stream as needed is ever made explicit (and then memoized, so
# that it does not have to be evaluated again).
#
# Instead of using the convential attribute names 'car' and 'cdr' or
# 'head' and 'tail', we use 'first' for the first element and 'rest'
# for the rest of the stream.
#
# Some methods such as 'each' or 'toArray' force evaluation of the
# complete stream, which means that they will never return on infinite
# streams.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


{ recur, resolve } =
  if typeof(require) != 'undefined'
    require.paths.unshift __dirname
    require('trampoline')
  else
    this.pazy


class Stream
  constructor: (@first__, rest) ->
    @rest = if rest?
      => val = rest(); (@rest = -> val)()
    else
      -> null

  first: -> @first__

  takeWhile: (pred) ->
    new Stream(@first(), => @rest()?.takeWhile(pred)) if pred(@first())

  take: (n) -> new Stream(@first(), => @rest()?.take(n-1)) if n > 0

  get: (n) -> this.drop(n)?.first() if n >= 0

  map: (func) -> new Stream(func(@first()), => @rest()?.map(func))

  select: (pred) ->
    if pred(@first())
      new Stream(@first(), => @rest()?.select(pred))
    else
      @rest()?.select(pred)

  combine: (other, op) ->
    new Stream(op(this.first(), other.first()), =>
      if this.rest() and other.rest()
        this.rest().combine(other.rest(), op)
    )

  plus:  (other) -> @combine(other, (a,b) -> a + b)
  minus: (other) -> @combine(other, (a,b) -> a - b)
  times: (other) -> @combine(other, (a,b) -> a * b)
  by:    (other) -> @combine(other, (a,b) -> a / b)

  accumulate: (start, op) ->
    first = op(start, @first())
    new Stream(first, => @rest()?.accumulate(first, op))

  sums:     -> @accumulate(0, (a,b) -> a + b)
  products: -> @accumulate(1, (a,b) -> a * b)

  merge: (other) ->
    new Stream(@first(), => if other then other.merge(@rest()) else @rest())

  concatl: (next) ->
    new Stream(@first(), => if @rest() then @rest().concatl(next) else next())

  concat: (other) -> @concatl(=> other)

  flatten: ->
    if @first()
      @first().concatl(=> @rest()?.flatten())
    else
      @rest()?.flatten()

  flatMap: (func) -> @map(func).flatten()

  cartesian: (stream) -> @flatMap((a) -> stream.map((b) -> [a,b]))

  toString: -> "Stream(#{@first()}, ...)"

  # The following functions force evaluation of the complete stream or
  # portions of the stream.

  dropWhile: (pred) ->
    step = (s) -> if s and pred(s.first()) then recur -> step(s.rest()) else s
    resolve step(this)

  drop: (n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s.rest(), n - 1) else s
    resolve step(this, n)

  each: (func) ->
    step = (s) -> if s then func(s.first()); recur -> step(s.rest())
    resolve step(this)

  reverse: ->
    step = (r, s) ->
      if s then recur -> step(new Stream(s.first(), -> r), s.rest()) else r
    resolve step(null, this)

  @cached: (name, f) -> @::[name] = -> x = f.apply(this); (@[name] = -> x)()

  @cached 'size', ->
    step = (s, n) -> if s then recur -> step(s.rest(), n + 1) else n
    resolve step(this, 0)

  @cached 'last', ->
    step = (s) -> if s.rest() then recur -> step(s.rest()) else s.first()
    resolve step(this)

  toArray: ->
    buffer = []
    @each (x) -> buffer.push(x)
    buffer

# Convenience methods for constructing some simple streams

Stream.iterate = (start, step) ->
  new Stream(start, -> Stream.iterate(step(start), step))

Stream.from = (start) -> new Stream(start, -> Stream.from(start + 1))

Stream.range = (start, end) -> Stream.from(start).take(end - start + 1)

Stream.fromArray = (a) ->
  n = a.length
  partial = (i) -> if i < n then new Stream(a[i], -> partial(i+1)) else null
  partial(0)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Stream = Stream
