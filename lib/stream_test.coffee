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

  combine: (other, op) ->
    new Stream(op(this.first, other.first), =>
      this.rest().combine(other.rest(), op) if this.rest() and other.rest())

  plus: (other) -> this.combine(other, (a,b) -> a + b)

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

puts "new Stream(1, -> new Stream(2)):"
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
puts
