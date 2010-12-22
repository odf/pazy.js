if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
else
  { Sequence } = this.pazy


describe "A sequence made of the numbers 1 and 2", ->
  s = new Sequence [1, 2]

  it "should have the elements 1 and 2 in that order", ->
    expect(s.toArray()).toEqual [1,2]

  it "should have size 2", ->
    expect(s.size()).toBe 2

  it "should start with a 1", ->
    expect(s.first()).toBe 1

  it "should end with a 2", ->
    expect(s.last()).toBe 2

  it "should print as 'Sequence(1, ...)'", ->
    expect(s.toString()).toEqual "Sequence(1, ...)"

  it "should print as '1,2' when converted to an array", ->
    expect(s.toArray().toString()).toEqual "1,2"


describe "A sequence made from the array ['a', 's', 'd', 'f']", ->
  s = new Sequence ['a', 's', 'd', 'f']

  it "should have size 4", ->
    expect(s.size()).toBe 4

  it "should start with an 'a'", ->
    expect(s.first()).toBe 'a'

  it "should end with an 'f'", ->
    expect(s.last()).toBe 'f'

  it "should have an 's' at position 1", ->
    expect(s.get 1).toBe 's'

  it "should have an 'd' at position 2", ->
    expect(s.get 2).toBe 'd'

  it "should not have anything at position 4", ->
    expect(s.get 4).toBe undefined

  it "should not have anything at position -1", ->
    expect(s.get -1).toBe undefined

  it "should be empty when five elements are dropped", ->
    expect(s.drop 5).toBe null

  it "should print as Sequence(a, ...)", ->
    expect(s.toString()).toEqual "Sequence(a, ...)"

  it "should print as 'a,s,d,f' when converted to an array", ->
    expect(s.toArray().toString()).toEqual "a,s,d,f"

  describe "when reversed", ->
    r = s.reverse()

    it "should have size 4", ->
      expect(r.size()).toBe 4

    it "should start with an 'f'", ->
      expect(r.first()).toBe 'f'

    it "should end with an 'a'", ->
      expect(r.last()).toBe 'a'

    it "should have an 'd' at the second position", ->
      expect(r.get 1).toBe 'd'

    it "should have an 's' at the third position", ->
      expect(r.get 2).toBe 's'

    it "should print as Sequence(f, ...)", ->
      expect(r.toString()).toEqual "Sequence(f, ...)"

    it "should print as 'f,d,s,a' when converted to an array", ->
      expect(r.toArray().toString()).toEqual "f,d,s,a"

  describe "when appended to its own reverse", ->
    t = s.reverse().concat s

    it "should have size 8", ->
      expect(t.size()).toBe 8

    it "should contain the elements f,d,s,a,a,s,d,f in that order", ->
      expect(t.toArray()).toEqual ['f', 'd', 's', 'a', 'a', 's', 'd', 'f']

describe "A sequence containing the squares of the numbers from 101 to 110", ->
  s = Sequence.range(101, 110).map (n) -> n * n

  it "should start with 10201", ->
    expect(s.first()).toEqual 10201

  it "should end with 12100", ->
    expect(s.last()).toBe 12100

  it "should have 10 elements", ->
    expect(s.size()).toBe 10

  it "should have 6 elements larger than 11000", ->
    expect(s.dropWhile((n) -> n <= 11000).size()).toBe 6

  it "should have 5 odd elements", ->
    expect(s.select((n) -> n % 2 == 1).size()).toBe 5

  it "should produce the partial seq 10201, 10404, 10609 on take(3)", ->
    expect(s.take(3).toArray()).toEqual [10201, 10404, 10609]

  it "should produce a sequence of 4 elements smaller than 11000", ->
    expect(s.takeWhile((n) -> n < 11000).toArray())
      .toEqual [10201, 10404, 10609, 10816]

describe "A sequence containing the first 10 triangle numbers", ->
  s = Sequence.range(1, 10).sums()

  it "should have 10 elements", ->
    expect(s.size()).toEqual 10

  it "should end with 55", ->
    expect(s.last()).toEqual 55

  it "should produce the correct sequence when multiplied with its reverse", ->
    t = new Sequence [55,135,216,280,315]
    expect(s.times(s.reverse()).equals(t.concat(t.reverse()))).toBe true

  it """should produce the numbers 1,1,3,2,6,3,10,4,15,21,28,36,45,55
        when merged with the sequence 1,2,3,4""", ->
    expect(s.merge(Sequence.range(1,4)).toArray())
      .toEqual [1,1,3,2,6,3,10,4,15,21,28,36,45,55]

describe "A sequence containing pairs (a,b) with a in 1,2 and b in 1,2,3", ->
  s = Sequence.range(1, 2).cartesian Sequence.range(1, 3)

  it "should have six elements", ->
    expect(s.size()).toBe 6

  it "should start with [1,1]", ->
    expect(s.first()).toEqual [1,1]

  it "should end with [2,3]", ->
    expect(s.last()).toEqual [2,3]

  it "should contain the expected elements", ->
    expect(s.toArray()).toEqual [[1,1], [1,2], [1,3], [2,1], [2,2], [2,3]]

describe "A sequence implementing the Fibonacci numbers", ->
  s = (Sequence.conj 0, -> Sequence.conj 1, -> s.rest().plus s).stored()

  it "should print as 'Sequence(0, ...)'", ->
    expect(s.toString()).toEqual "Sequence(0, ...)"

  it "should start with the numbers 0, 1, 1, 2, 3, 5, 8, 13, 21 and 34", ->
    expect(s.take(10).toArray()).toEqual [0,1,1,2,3,5,8,13,21,34]

  it "should have 102334155 at position 40", ->
    expect(s.get(40)).toBe 102334155

  it "should have 1346269 as the first element larger than a million", ->
    expect(s.dropWhile((n) -> n <= 1000000).first()).toBe 1346269

  it "should have 9227465 as the last element smaller than ten millions", ->
    expect(s.takeWhile((n) -> n < 10000000).last()).toBe 9227465

  it "should have 0, 2, 8, 34, 144, 610 and 2584 as the first even elements", ->
    result = [0, 2, 8, 34, 144, 610, 2584]
    expect(s.select((n) -> n % 2 == 0).take(7).toArray()).toEqual result

  it "should have the first partial sums 0, 1, 2, 4, 7, 12, 20 and 33", ->
    expect(s.sums().take(8).toArray()).toEqual [0,1,2,4,7,12,20,33]

  it "should have the first partial products 1, 1, 2, 6, 30, 240 and 3120", ->
    result = [1, 1, 2, 6, 30, 240, 3120]
    expect(s.rest().products().take(7).toArray()).toEqual result

  it "should have 45 elements under a billion", ->
    expect(s.takeWhile((n) -> n < 1000000000).size()).toBe 45

  describe "when combined into pairs of consecutive entries", ->
    pairs = s.combine(s.rest(), (a, b) -> [a, b])

    it "should start with the pairs (0,1), (1,1), (1,2) and (2,3)", ->
      expect(pairs.take(4).toArray()).toEqual [[0,1], [1,1], [1,2], [2,3]]

describe "The sequence of prime numbers", ->
  isPrime = (n) ->
    n < 4 or primes.takeWhile((m) -> m * m <= n).forall (m) -> n % m

  primes = Sequence.from(2).select(isPrime).stored()

  it "should start with the number 2, 3, 5, 7, 11, 13, 17, 19, 23 and 29", ->
    expect(primes.take(10).toArray()).toEqual [2,3,5,7,11,13,17,19,23,29]

  it "should have 997 as the largest element under 1000", ->
    expect(primes.takeWhile((n) -> n < 1000).last()).toBe 997

  describe "when merged with the fibonacci numbers startin at 2", ->
    fib = Sequence.conj 0, -> Sequence.conj 1, -> fib.rest().plus fib
    seq = primes.merge fib.drop 3

    it "should start with the elements 2,2,3,3,5,5,7,8,11,13,13 and 21", ->
      expect(seq.take(12).toArray()).toEqual [2,2,3,3,5,5,7,8,11,13,13,21]

describe "A forced sequence", ->
  log = []
  s = Sequence.range(0, 9).map((x) -> log.push(x); x * x).forced()

  it "should be executed completely before members are accessed", ->
    expect(log).toEqual [0..9]

  it "should contain the right values", ->
    expect(s.toArray()).toEqual (x * x for x in [0..9])

  it "should never be executed again", ->
    expect(s.size()).toEqual 10
    expect(log).toEqual [0..9]

describe "A stored sequence", ->
  log = []
  s = Sequence.range(0, 9).map((x) -> log.push(x); x * x).stored()

  it "should only have the first member evaluated up front", ->
    expect(log).toEqual [0]

  it "should contain the right values", ->
    expect(s.toArray()).toEqual (x * x for x in [0..9])

  it "should not be executed more than once", ->
    expect(s.last()).toEqual 81
    expect(s.size()).toEqual 10
    expect(log).toEqual [0..9]

describe "A default sequence", ->
  log = []
  s = Sequence.range(0, 9).map((x) -> log.push(x); x * x)

  it "should only have the first member evaluated up front", ->
    expect(log).toEqual [0]

  it "should contain the right values", ->
    expect(s.toArray()).toEqual (x * x for x in [0..9])

  it "should be executed each time it is accessed", ->
    expect(s.last()).toEqual 81
    expect(s.size()).toEqual 10
    expect(log.length).toBeGreaterThan 10
