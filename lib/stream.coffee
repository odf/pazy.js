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
# for the rest of the stream. Note that 'first' is a value whereas
# 'rest' and 'last' are functions.
#
# Some methods such as 'each' or 'toArray' force evaluation of the
# complete stream, which means that they will never return on infinite
# streams.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


class Stream
  constructor: (@first, rest) ->
    @rest = if rest?
      => val = rest(); (@rest = -> val)()
    else
      -> null

  take_while: (pred) ->
    if pred(@first)
      new Stream(@first, => if @rest() then @rest().take_while(pred))

  take: (n) ->
    if n > 0
      new Stream(@first, => if @rest() then @rest().take(n-1))

  get: (n) -> this.drop(n).first

  map: (func) ->
    new Stream(func(@first), => if @rest() then @rest().map(func))

  select: (pred) ->
    if pred(@first)
      new Stream(@first, => if @rest() then @rest().select(pred))
    else
      if @rest then @rest().select(pred)

  combine: (other, op) ->
    new Stream(op(this.first, other.first), =>
      if this.rest() and other.rest()
        this.rest().combine(other.rest(), op)
    )

  plus:  (other) -> @combine(other, (a,b) -> a + b)
  minus: (other) -> @combine(other, (a,b) -> a - b)
  times: (other) -> @combine(other, (a,b) -> a * b)
  by:    (other) -> @combine(other, (a,b) -> a / b)

  accumulate: (start, op) ->
    first = op(start, @first)
    new Stream(first, => if @rest() then @rest().accumulate(first, op))

  sums:     -> @accumulate(0, (a,b) -> a + b)
  products: -> @accumulate(1, (a,b) -> a * b)

  merge: (other) -> new Stream(@first, => if other then other.merge(@rest()))

  concatl: (next) ->
    new Stream(@first, => if @rest() then @rest().concatl(next) else next())

  concat: (other) -> @concatl(=> other)

  flatten: -> @first.concatl(=> if @rest() then @rest().flatten())

  flat_map: (func) -> @map(func).flatten()

  cartesian: (stream) -> @flat_map((a) -> stream.map((b) -> [a,b]))

  toString: -> "Stream(#{@first}, ...)"

  # The following functions force evaluation of the complete stream or
  # portiosn of the stream. Since Javascript does not optimize tail
  # recursion, iterative implementations were chosen instead of the
  # cleaner recursive versions in order to avoid stack overflow when
  # streams get large.

  drop_while: (pred) ->
    stream = this
    while stream and pred(stream.first)
      stream = stream.rest()
    stream

  drop: (n) ->
    stream = this
    i = n
    while stream and i > 0
      stream = stream.rest()
      i -= 1
    stream

  each: (func) ->
    stream = this
    while stream
      val = func(stream.first)
      stream = stream.rest()
    val

  reverse: ->
    rev = null
    @each (x) ->
      t = rev
      rev = new Stream(x, -> t)
    rev

  size: ->
    count = 0
    @each -> count += 1

  last: ->
    stream = this
    while stream.rest()
      stream = stream.rest()
    stream.first

  toArray: ->
    buffer = []
    @each (x) -> buffer.push(x)
    buffer

# Convenience methods for constructing some simple streams

Stream.iterate = (start, step) ->
  new Stream(start, -> Stream.iterate(step(start), step))

Stream.from = (start) -> new Stream(start, -> Stream.from(start + 1))

Stream.range = (start, end) -> Stream.from(start).take(end - start + 1)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.Stream = Stream
else
  exports.Stream = Stream
