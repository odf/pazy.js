if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { sequence } = require('sequence')
else
  { sequence } = this.pazy

seq = sequence


describe "A sequence made of the numbers 1 and 2", ->
  s = seq [1, 2]

  it "should have the elements 1 and 2 in that order", ->
    expect(seq.toArray s).toEqual [1,2]

  it "should have size 2", ->
    expect(seq.size s).toBe 2

  it "should start with a 1", ->
    expect(s.first()).toBe 1

  it "should end with a 2", ->
    expect(seq.last s).toBe 2

  it "should print as '(1, ...)'", ->
    expect(seq.toString s).toEqual "(1, ...)"

  it "should print as '1,2' when converted to an array", ->
    expect(seq.toArray(s).toString()).toEqual "1,2"


describe "A sequence made from the array ['a', 's', 'd', 'f']", ->
  s = seq ['a', 's', 'd', 'f']

  it "should have size 4", ->
    expect(seq.size s).toBe 4

  it "should start with an 'a'", ->
    expect(s.first()).toBe 'a'

  it "should end with an 'f'", ->
    expect(seq.last s).toBe 'f'

  it "should have an 's' at position 1", ->
    expect(seq.get s, 1).toBe 's'

  it "should have an 'd' at position 2", ->
    expect(seq.get s, 2).toBe 'd'

  it "should not have anything at position 4", ->
    expect(seq.get s, 4).toBe undefined

  it "should not have anything at position -1", ->
    expect(seq.get s, -1).toBe undefined

  it "should be empty when five elements are dropped", ->
    expect(seq.drop s, 5).toBe null

  it "should print as (a, ...)", ->
    expect(seq.toString s).toEqual "(a, ...)"

  it "should print as 'a,s,d,f' when converted to an array", ->
    expect(seq.toArray(s).toString()).toEqual "a,s,d,f"

  describe "when reversed", ->
    r = seq.reverse s

    it "should have size 4", ->
      expect(seq.size r).toBe 4

    it "should start with an 'f'", ->
      expect(r.first()).toBe 'f'

    it "should end with an 'a'", ->
      expect(seq.last r).toBe 'a'

    it "should have an 'd' at the second position", ->
      expect(seq.get r, 1).toBe 'd'

    it "should have an 's' at the third position", ->
      expect(seq.get r, 2).toBe 's'

    it "should print as (f, ...)", ->
      expect(seq.toString r).toEqual "(f, ...)"

    it "should print as 'f,d,s,a' when converted to an array", ->
      expect(seq.toArray(r).toString()).toEqual "f,d,s,a"

  describe "when appended to its own reverse", ->
    test = seq.concat seq.reverse(s), s

    it "should have size 8", ->
      expect(seq.size test).toBe 8

    it "should contain the elements f,d,s,a,a,s,d,f in that order", ->
      expect(seq.toArray test).toEqual ['f', 'd', 's', 'a', 'a', 's', 'd', 'f']

describe "A sequence containing the squares of the numbers from 101 to 110", ->
  s = seq.map seq.range(101, 110), (n) -> n * n

  it "should start with 10201", ->
    expect(s.first()).toEqual 10201

  it "should end with 12100", ->
    expect(seq.last s).toBe 12100

  it "should have 10 elements", ->
    expect(seq.size s).toBe 10

  it "should have 6 elements larger than 11000", ->
    expect(seq.size seq.dropWhile(s, (n) -> n <= 11000)).toBe 6

  it "should have 5 odd elements", ->
    expect(seq.size seq.select(s, (n) -> n % 2 == 1)).toBe 5

  it "should produce the partial seq 10201, 10404, 10609 on take(3)", ->
    expect(seq.toArray seq.take(s, 3)).toEqual [10201, 10404, 10609]

  it "should produce a sequence of 4 elements smaller than 11000", ->
    expect(seq.toArray seq.takeWhile(s, (n) -> n < 11000))
      .toEqual [10201, 10404, 10609, 10816]

# describe "A sequence containing the first 10 triangle numbers", ->
#   seq = seq.range(1, 10).sums()

#   it "should have 10 elements", ->
#     expect(seq.size()).toEqual 10

#   it "should end with 55", ->
#     expect(seq.last()).toEqual 55

#   it "should produce the correct sequence when multiplied with its reverse", ->
#     test = seq.fromArray([55,135,216,280,315])
#     expect(seq.times(seq.reverse()).equals(test.concat(test.reverse())))
#       .toBe true

#   it """should produce the numbers 1,1,3,2,6,3,10,4,15,21,28,36,45,55
#         when merged with the sequence 1,2,3,4""", ->
#     expect(seq.merge(seq.range(1,4)).toArray())
#       .toEqual [1,1,3,2,6,3,10,4,15,21,28,36,45,55]

# describe "A sequence containing pairs (a,b) with a in 1,2 and b in 1,2,3", ->
#   seq = seq.range(1, 2).cartesian seq.range(1, 3)

#   it "should have six elements", ->
#     expect(seq.size()).toBe 6

#   it "should start with [1,1]", ->
#     expect(seq.first()).toEqual [1,1]

#   it "should end with [2,3]", ->
#     expect(seq.last()).toEqual [2,3]

#   it "should contain the expected elements", ->
#     expect(seq.toArray()).toEqual [[1,1], [1,2], [1,3], [2,1], [2,2], [2,3]]
