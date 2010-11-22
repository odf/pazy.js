suspend = (code) ->
  cache = {
    force: ->
      val = code()
      this.force = () -> val
      val
  }
  -> cache.force()

class Stream
  constructor: (@first, rest) ->
    @rest = if rest? then suspend(rest) else -> null

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

  get: (n) -> drop(n).first

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

  plus:  (other) -> this.combine(other, (a,b) -> a + b)
  minus: (other) -> this.combine(other, (a,b) -> a - b)
  times: (other) -> this.combine(other, (a,b) -> a * b)
  by:    (other) -> this.combine(other, (a,b) -> a / b)

  accumulate: (start, op) ->
    new_start = op(start, @first)
    new Stream(new_start, => @rest().accumulate(new_start, op) if @rest())

  sums:     -> this.accumulate(0, (a,b) -> a + b)
  products: -> this.accumulate(1, (a,b) -> a * b)

  merge: (other) -> new Stream(@first, => other.merge(@rest()) if other)

  concat: (other) ->
    new Stream(@first, => if @rest() then @rest().concat(other) else other)

  # CAUTION: don't call the following methods on an infinite stream.
  last: ->
    stream = this
    while stream.rest()
      stream = stream.rest()
    stream.first

  toArray: ->
    stream = this
    results = []
    while stream?
      results.push stream.first
      stream = stream.rest()
    results

  toString: ->
    this.toArray().join(', ')

Stream.iterate = (start, step) ->
  new Stream(start, -> Stream.iterate(step(start), step))

Stream.from = (start) -> Stream.iterate(start, (n) -> n + 1)


#-------------------------------------

puts = (s) -> print (if s? then s else '') + "\n"

puts "A stream with just the numbers 1 and 2:"
puts new Stream(1, -> new Stream(2))
puts()

fibonacci = new Stream(0, -> new Stream(1, -> fibonacci.rest().plus fibonacci))

puts "The first 100 Fibonacci numbers:"
puts fibonacci.take(100)
puts()

puts "The Fibonacci numbers between and 1000 and 100000:"
puts fibonacci.drop_while((n) ->  n < 1000).take_while((n) ->  n < 100000)
puts()

puts "The squares of the number from 101 to 110:"
puts Stream.from(1).drop(100).map((n) -> n * n).take(10)
puts()

puts "The accumulated products of the numbers from 1 to 10:"
puts Stream.from(1).products().take(10)
puts()

puts "The first 12 Fibonacci numbers with running positions:"
puts fibonacci.combine(Stream.from(0), (x, i) -> "#{i}: #{x}").take(12)
puts()

puts "The same merged into a single sequence:"
puts Stream.from(0).merge(fibonacci).take(24)
puts()

puts "The concatenation of the two streams:"
puts Stream.from(0).take(12).concat(fibonacci.take(12))
puts()

puts "The first 10 even fibonacci numbers:"
puts fibonacci.select((n) -> n % 2 == 0).take(10)
puts()

puts "The largest Fibonacci number under 1,000,000:"
puts fibonacci.take_while((n) ->  n < 1000000).last()
puts()
