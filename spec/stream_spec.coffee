if typeof(require) != 'undefined'
  require.paths.unshift './lib'
  Stream = require('stream').Stream
else
  Stream = pazy.Stream


describe "A Stream made of the numbers 1 and 2", ->
  stream = new Stream(1, -> new Stream(2))

  it "should have the elements 1 and 2 in that order", ->
    expect(stream.toArray()).toEqual [1,2]

  it "should have size 2", ->
    expect(stream.size()).toBe 2

  it "should start with a 1", ->
    expect(stream.first).toBe 1

  it "should end with a 2", ->
    expect(stream.last()).toBe 2

  it "should print as 'Stream(1, ...)'", ->
    expect(stream.toString()).toEqual "Stream(1, ...)"

  it "should print as '1,2' when converted to an array", ->
    expect(stream.toArray().toString()).toEqual "1,2"

describe "A stream implementing the recursion formula for Fibonacci numbers", ->
  stream = new Stream(0, -> new Stream(1, -> stream.rest().plus stream))

  it "should print as 'Stream(0, ...)'", ->
    expect(stream.toString()).toEqual "Stream(0, ...)"

  it "should start with the numbers 0, 1, 1, 2, 3, 5, 8, 13, 21 and 34", ->
    expect(stream.take(10).toArray()).toEqual [0,1,1,2,3,5,8,13,21,34]

  it "should have 102334155 at position 40", ->
    expect(stream.get(40)).toBe 102334155

  it "should have 1346269 as the first element larger than a million", ->
    expect(stream.drop_while((n) -> n <= 1000000).first).toBe 1346269

  it "should have 9227465 as the last element smaller than ten millions", ->
    expect(stream.take_while((n) -> n < 10000000).last()).toBe 9227465

  it "should have 0, 2, 8, 34, 144, 610 and 2584 as the first even elements", ->
    result = [0, 2, 8, 34, 144, 610, 2584]
    expect(stream.select((n) -> n % 2 == 0).take(7).toArray()).toEqual result

  it "should have the first partial sums 0, 1, 2, 4, 7, 12, 20 and 33", ->
    expect(stream.sums().take(8).toArray()).toEqual [0,1,2,4,7,12,20,33]

  it "should have the first partial products 1, 1, 2, 6, 30, 240 and 3120", ->
    result = [1, 1, 2, 6, 30, 240, 3120]
    expect(stream.rest().products().take(7).toArray()).toEqual result

  it "should have 45 elements under a billion", ->
    expect(stream.take_while((n) -> n < 1000000000).size()).toBe 45

  describe "when combined into pairs of consecutive entries", ->
    pairs = stream.combine(stream.rest(), (a, b) -> [a, b])

    it "should start with the pairs (0,1), (1,1), (1,2) and (2,3)", ->
      expect(pairs.take(4).toArray()).toEqual [[0,1], [1,1], [1,2], [2,3]]

describe "A stream implementing a simple prime number sieve", ->
  next   = (s) -> sieve(s.rest().select((n) -> n % s.first != 0))
  sieve  = (s) -> new Stream(s.first, -> next(s))
  primes = sieve(Stream.from(2))

  it "should start with the number 2, 3, 5, 7, 11, 13, 17, 19, 23 and 29", ->
    expect(primes.take(10).toArray()).toEqual [2,3,5,7,11,13,17,19,23,29]

  it "should have 997 as the largest element under 1000", ->
    expect(primes.take_while((n) -> n < 1000).last()).toBe 997

  describe "when merged with the fibonacci numbers startin at 2", ->
    fib = new Stream(0, -> new Stream(1, -> fib.rest().plus fib))
    stream = primes.merge(fib.drop(3))

    it "should start with the elements 2,2,3,3,5,5,7,8,11,13,13 and 21", ->
      expect(stream.take(12).toArray()).toEqual [2,2,3,3,5,5,7,8,11,13,13,21]

describe "A stream containing the squares of the numbers from 101 to 110", ->
  stream = Stream.from(1).drop(100).map((n) -> n * n).take(10)

  it "should print as 'Stream(10201, ...)'", ->
    expect(stream.toString()).toEqual "Stream(10201, ...)"

  it "should end with 12100", ->
    expect(stream.last()).toBe 12100

  it "should have 10 elements", ->
    expect(stream.size()).toBe 10

describe "A stream containing pairs (a,b) with a in 1,2 and b in 1,2,3", ->
  stream = Stream.range(1, 2).cartesian Stream.range(1, 3)

  it "should have four elements", ->
    expect(stream.size()).toBe 6

  it "should start with [1,1]", ->
    expect(stream.first).toEqual [1,1]

  it "should end with [2,3]", ->
    expect(stream.last()).toEqual [2,3]

  it "should contain the expected elements", ->
    expect(stream.toArray()).toEqual [[1,1], [1,2], [1,3], [2,1], [2,2], [2,3]]
