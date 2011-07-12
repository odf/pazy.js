if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence, seq }   = require('sequence')
  { IntSet, HashSet } = require('indexed')
  require 'sequence_extras'
else
  { seq, IntSet, HashSet } = this.pazy

Seq = Sequence

describe "A sequence", ->
  describe "made of the numbers 1 and 2", ->
    s = seq [1, 2]

    it "should have the elements 1 and 2 in that order", ->
      expect(s.into []).toEqual [1,2]

    it "should have size 2", ->
      expect(s.size()).toBe 2

    it "should start with a 1", ->
      expect(s.first()).toBe 1

    it "should end with a 2", ->
      expect(s.last()).toBe 2

    it "should return 2 on max", ->
      expect(s.max()).toBe 2

    it "should return 1 on min", ->
      expect(s.min()).toBe 1

    it "should print as '(1, 2)'", ->
      expect(s.toString()).toEqual "(1, 2)"

    it "should print as '1,2' when converted to an array", ->
      expect(s.into([]).toString()).toEqual "1,2"

    it "should produce the string '1--2' when joined with --", ->
      expect(s.join '--').toEqual '1--2'

    it "should compare equal to a sequence with the same elements", ->
      expect(s.equals [1,2]).toBe true

    it "should combine correctly with another sequence", ->
      expect(s.combine([1,2,1], (a,b) -> a == b).into []).
        toEqual [true, true, false]

    it "should not compare equal to the same sequence with a one appended", ->
      expect(s.equals [1,2,1]).toBe false

    it "should not compare equal to the same sequence with a zero appended", ->
      expect(s.equals [1,2,0]).toBe false

  describe "which is empty", ->
    s = seq null

    it "should be empty", ->
      expect(Seq.empty s).toBe true

    it "should have length 0", ->
      expect(Seq.size s).toBe 0

    it "should return undefined when asked for its last element", ->
      expect(Seq.last s).toBe undefined

    it "should return null when asked for its leading two-element sublist", ->
      expect(Seq.take s, 2).toBe null

    it "should return null when takeWhile is applied", ->
      expect(Seq.takeWhile s, (x) -> true).toBe null

    it "should return null when asked to drop zero elements", ->
      expect(Seq.drop s, 0).toBe null

    it "should return null when asked to drop two elements", ->
      expect(Seq.drop s, 2).toBe null

    it "should return null when dropWhile is applied", ->
      expect(Seq.dropWhile s, (x) -> false).toBe null

    it "should return undefined when asked to grab any element by an index", ->
      expect(Seq.get s, i).toBe undefined for i in [-1..2]

    it "should return null when anything is selected", ->
      expect(Seq.select s, (x) -> true).toBe null

    it "should return undefined on find", ->
      expect(Seq.find s, (x) -> true).toBe undefined

    it "should return true on forall", ->
      expect(Seq.forall s, (x) -> true).toBe true

    it "should return null on map", ->
      expect(Seq.map s, (x) -> x * x).toBe null

    it "should return null on accumulate", ->
      expect(Seq.accumulate s, (s, x) -> s * x).toBe null

    it "should return null on sums", ->
      expect(Seq.sums s).toBe null

    it "should return 0 on sum", ->
      expect(Seq.sum s).toBe 0

    it "should return 0 on product", ->
      expect(Seq.product s).toBe 1

    it "should return undefined on max", ->
      expect(Seq.max s).toBe undefined

    it "should return undefined on min", ->
      expect(Seq.min s).toBe undefined

    it "should leave a sequence it is combined with as is", ->
      expect(Seq.combine(s, [1..5], (a, b) -> a + b).into []).toEqual [1..5]

    it "should leave a sequence it is added to as is", ->
      expect(Seq.add(s, [1..5]).into []).toEqual [1..5]

    it "should test equal to any other empty sequence", ->
      expect(Seq.equals s, null).toBe true
      expect(Seq.equals s, seq()).toBe true
      expect(Seq.equals s, []).toBe true

    it "should not test equal to a non-empty sequence", ->
      expect(Seq.equals s, [1]).toBe false

    it "should reproduce any sequence it is interleaved with", ->
      expect(Seq.interleave(s, [1..5]).into []).toEqual [1..5]
      expect(Seq.interleave([1..5], s).into []).toEqual [1..5]

    it "should reproduce any sequence it is concatenated with", ->
      expect(Seq.concat(s, [1..5]).into []).toEqual [1..5]
      expect(Seq.concat([1..5], s).into []).toEqual [1..5]

    it "should return null on flatten", ->
      expect(Seq.flatten s).toEqual null

    it "should be skipped over when flattening", ->
      expect(Seq.flatten([[1,2], s, [3,4], s, [5,6]]).into []).toEqual [1..6]

    it "should have null as its cartesian product with any other sequence", ->
      expect(Seq.cartesian s, [1..5]).toBe null

    it "should still be empty when uniq is applied", ->
      expect(Seq.uniq s).toBe null

    it "should not pass any elements into a function applied via each", ->
      log = []
      Seq.each s, (x) -> log.push x
      expect(log).toEqual []

    it "should return null when reversed", ->
      expect(Seq.reverse s).toBe null

    it "should return null on forced", ->
      expect(Seq.forced s).toBe null

    it "should leave any empty sequences empty when injected into them", ->
      class List
        constructor: (car, cdr) ->
          @first = -> car
          @rest  = -> cdr
          empty = typeof(car) == 'undefined'
          @empty = -> empty
        plus:  (x) -> new List(x, this)

      expect(Seq.into s, []).toEqual []
      expect(Seq.into s, null).toBe null
      expect(Seq.into(s, new List()).empty()).toBe true

    it "should print as ()", ->
      expect(Seq.toString s).toEqual '()'

    it "should produce an empty string if joined with --", ->
      expect(Seq.join s, '--').toEqual ''


  describe "of ten times the letter 'A'", ->
    s = Sequence.constant('A').take(10)

    it "should have size 10", ->
      expect(s.size()).toBe 10

    it "should start with an 'A'", ->
      expect(s.first()).toBe 'A'

    it "should end with an 'A'", ->
      expect(s.last()).toBe 'A'

    Sequence.range(0,9).each (i) ->
      it "should have an 'A' at position #{i}", ->
        expect(s.get(i)).toBe 'A'

  describe "made from the array ['a', 's', 'd', 'f']", ->
    s = seq ['a', 's', 'd', 'f']

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

    it "should return 's' on max", ->
      expect(s.max()).toBe 's'

    it "should return 'a' on min", ->
      expect(s.min()).toBe 'a'

    it "should print as (a, s, d, f)", ->
      expect(s.toString()).toEqual "(a, s, d, f)"

    it "should print as 'a,s,d,f' when converted to an array", ->
      expect(s.into([]).toString()).toEqual "a,s,d,f"

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

      it "should print as (f, d, s, a)", ->
        expect(r.toString()).toEqual "(f, d, s, a)"

      it "should print as 'f,d,s,a' when converted to an array", ->
        expect(r.into([]).toString()).toEqual "f,d,s,a"

    describe "when appended to its own reverse", ->
      t = s.reverse().concat s

      it "should have size 8", ->
        expect(t.size()).toBe 8

      it "should contain the elements f,d,s,a,a,s,d,f in that order", ->
        expect(t.into []).toEqual ['f', 'd', 's', 'a', 'a', 's', 'd', 'f']

  describe "containing the squares of the numbers from 101 to 110", ->
    s = Seq.range(101, 110).map (n) -> n * n

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
      expect(s.take(3).into []).toEqual [10201, 10404, 10609]

    it "should produce a sequence of 4 elements smaller than 11000", ->
      expect(s.takeWhile((n) -> n < 11000).into [])
        .toEqual [10201, 10404, 10609, 10816]

  describe "containing the first 10 triangle numbers", ->
    s = Seq.range(1, 10).sums()

    it "should have 10 elements", ->
      expect(s.size()).toEqual 10

    it "should end with 55", ->
      expect(s.last()).toEqual 55

    it "should produce the correct sequence when multiplied with its reverse", ->
      t = seq [55,135,216,280,315]
      expect(s.mul(s.reverse()).equals(t.concat(t.reverse()))).toBe true

    it """should produce the numbers 1,1,3,2,6,3,10,4,15,21,28,36,45,55
          when interleaved with the sequence 1,2,3,4""", ->
      expect(s.interleave(Seq.range(1,4)).into [])
        .toEqual [1,1,3,2,6,3,10,4,15,21,28,36,45,55]

  describe "containing pairs (a,b) with a in 1,2 and b in 1,2,3", ->
    s = Seq.range(1, 2).cartesian Seq.range(1, 3)

    it "should have six elements", ->
      expect(s.size()).toBe 6

    it "should start with [1,1]", ->
      expect(s.first()).toEqual [1,1]

    it "should end with [2,3]", ->
      expect(s.last()).toEqual [2,3]

    it "should contain the expected elements", ->
      expect(s.into []).toEqual [[1,1], [1,2], [1,3], [2,1], [2,2], [2,3]]

    it "should contain the elements 1, 2, 3 after flatten() and uniq()", ->
      expect(s.flatten().uniq().into []).toEqual [1,2,3]

  describe "implementing the Fibonacci numbers", ->
    s = (Seq.conj 0, -> Seq.conj 1, -> s.rest().add s)

    it "should print as '(0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...)'", ->
      expect(s.toString()).toEqual "(0, 1, 1, 2, 3, 5, 8, 13, 21, 34, ...)"

    it "should start with the numbers 0, 1, 1, 2, 3, 5, 8, 13, 21 and 34", ->
      expect(s.take(10).into []).toEqual [0,1,1,2,3,5,8,13,21,34]

    it "should have 102334155 at position 40", ->
      expect(s.get(40)).toBe 102334155

    it "should have 1346269 as the first element larger than a million", ->
      expect(s.dropWhile((n) -> n <= 1000000).first()).toBe 1346269

    it "should have 9227465 as the last element smaller than ten millions", ->
      expect(s.takeWhile((n) -> n < 10000000).last()).toBe 9227465

    it "should have 0, 2, 8, 34, 144, 610 and 2584 as the first even elements", ->
      result = [0, 2, 8, 34, 144, 610, 2584]
      expect(s.select((n) -> n % 2 == 0).take(7).into []).toEqual result

    it "should have the first partial sums 0, 1, 2, 4, 7, 12, 20 and 33", ->
      expect(s.sums().take(8).into []).toEqual [0,1,2,4,7,12,20,33]

    it "should have the first partial products 1, 1, 2, 6, 30, 240 and 3120", ->
      result = [1, 1, 2, 6, 30, 240, 3120]
      expect(s.rest().products().take(7).into []).toEqual result

    it "should have 45 elements under a billion", ->
      expect(s.takeWhile((n) -> n < 1000000000).size()).toBe 45

    describe "when combined into pairs of consecutive entries", ->
      pairs = s.combine(s.rest(), (a, b) -> [a, b])

      it "should start with the pairs (0,1), (1,1), (1,2) and (2,3)", ->
        expect(pairs.take(4).into []).toEqual [[0,1], [1,1], [1,2], [2,3]]

  describe "of all prime numbers", ->
    isPrime = (n) ->
      n < 4 or primes.takeWhile((m) -> m * m <= n).forall (m) -> n % m

    primes = Seq.from(2).select(isPrime)

    it "should start with the number 2, 3, 5, 7, 11, 13, 17, 19, 23 and 29", ->
      expect(primes.take(10).into []).toEqual [2,3,5,7,11,13,17,19,23,29]

    it "should have 997 as the largest element under 1000", ->
      expect(primes.takeWhile((n) -> n < 1000).last()).toBe 997

    describe "when interleaved with the fibonacci numbers startin at 2", ->
      fib = Seq.conj 0, -> Seq.conj 1, -> fib.rest().add fib
      seq = primes.interleave fib.drop 3

      it "should start with the elements 2,2,3,3,5,5,7,8,11,13,13 and 21", ->
        expect(seq.take(12).into []).toEqual [2,2,3,3,5,5,7,8,11,13,13,21]

  describe "which is forced", ->
    log = []
    s = Seq.range(0, 9).map((x) -> log.push(x); x * x).forced()

    it "should be executed completely before members are accessed", ->
      expect(log).toEqual [0..9]

    it "should contain the right values", ->
      expect(s.into []).toEqual (x * x for x in [0..9])

    it "should never be executed again", ->
      expect(s.size()).toEqual 10
      expect(log).toEqual [0..9]

  describe "with default semantics", ->
    log = []
    s = Seq.range(0, 9).map((x) -> log.push(x); x * x)

    it "should only have the first member evaluated up front", ->
      expect(log).toEqual [0]

    it "should contain the right values", ->
      expect(s.into []).toEqual (x * x for x in [0..9])

    it "should not be executed more than once", ->
      expect(s.last()).toEqual 81
      expect(s.size()).toEqual 10
      expect(log).toEqual [0..9]

  describe "from an array of arrays, with empty ones and nulls mixed in", ->
    a = [[1,2,3],[],[4],null,[5,6],[7,[8,9]]]

    it "should produce the correct result when flattened", ->
      expect(Seq.flatten(a).into []).toEqual [1,2,3,4,5,6,7,[8,9]]

  describe "from an array with some holes in it", ->
    a = [0..3]
    a[6] = 6
    delete a[0]

    it "should be compacted", ->
      expect(Seq.into a, []).toEqual [1,2,3,6]

  describe "from an IntSet", ->
    s = new IntSet().plus 5, 3, 7, 2

    it "should be sorted", ->
      expect(Seq.into s, []).toEqual [2,3,5,7]
