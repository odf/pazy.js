{ List } =
  if typeof(require) != 'undefined'
    require.paths.unshift('#{__dirname}/../lib')
    require('list')
  else
    this.pazy


describe "A List made of the numbers 1 and 2", ->
  list = new List(1, new List(2))

  it "should have the elements 1 and 2 in that order", ->
    expect(list.toArray()).toEqual [1,2]

  it "should have size 2", ->
    expect(list.size()).toBe 2

  it "should start with a 1", ->
    expect(list.first()).toBe 1

  it "should end with a 2", ->
    expect(list.last()).toBe 2

  it "should print as 'List(1, 2)'", ->
    expect(list.toString()).toEqual "List(1, 2)"

  it "should print as '1,2' when converted to an array", ->
    expect(list.toArray().toString()).toEqual "1,2"

describe "A List made from the array ['a', 's', 'd', 'f']", ->
  list = List.fromArray(['a', 's', 'd', 'f'])

  it "should have size 4", ->
    expect(list.size()).toBe 4

  it "should start with an 'a'", ->
    expect(list.first()).toBe 'a'

  it "should end with an 'f'", ->
    expect(list.last()).toBe 'f'

  it "should have an 's' at position 1", ->
    expect(list.get(1)).toBe 's'

  it "should have an 'd' at position 2", ->
    expect(list.get(2)).toBe 'd'

  it "should not have anything at position 4", ->
    expect(list.get(4)).toBe undefined

  it "should not have anything at position -1", ->
    expect(list.get(-1)).toBe undefined

  it "should be empty when five elements are dropped", ->
    expect(list.drop(5)).toBe null

  it "should print as List(a, s, d, f)", ->
    expect(list.toString()).toEqual "List(a, s, d, f)"

  it "should print as 'a,s,d,f' when converted to an array", ->
    expect(list.toArray().toString()).toEqual "a,s,d,f"

  describe "when reversed", ->
    rev = list.reverse()

    it "should have size 4", ->
      expect(rev.size()).toBe 4

    it "should start with an 'f'", ->
      expect(rev.first()).toBe 'f'

    it "should end with an 'a'", ->
      expect(rev.last()).toBe 'a'

    it "should have an 'd' at the second position", ->
      expect(rev.get(1)).toBe 'd'

    it "should have an 's' at the third position", ->
      expect(rev.get(2)).toBe 's'

    it "should print as List(f, d, s, a)", ->
      expect(rev.toString()).toEqual "List(f, d, s, a)"

    it "should print as 'f,d,s,a' when converted to an array", ->
      expect(rev.toArray().toString()).toEqual "f,d,s,a"

  describe "when appended to its own reverse", ->
    test = list.reverseConcat(list)

    it "should have size 8", ->
      expect(test.size()).toBe 8

    it "should contain the elements f,d,s,a,a,s,d,f in that order", ->
      expect(test.toArray()).toEqual ['f', 'd', 's', 'a', 'a', 's', 'd', 'f']

describe "A list containing the squares of the numbers from 101 to 110", ->
  list = List.range(101, 110).map((n) -> n * n)

  it "should start with 10201", ->
    expect(list.first()).toEqual 10201

  it "should end with 12100", ->
    expect(list.last()).toBe 12100

  it "should have 10 elements", ->
    expect(list.size()).toBe 10

  it "should have 6 elements larger than 11000", ->
    expect(list.dropWhile((n) -> n <= 11000).size()).toBe 6

  it "should have 5 odd elements", ->
    expect(list.select((n) -> n % 2 == 1).size()).toBe 5

  it "should produce the partial list 10201, 10404, 10609 on take(3)", ->
    expect(list.take(3).toArray()).toEqual [10201, 10404, 10609]

  it "should produce a list of 4 elements smaller than 11000", ->
    expect(list.takeWhile((n) -> n < 11000).toArray())
      .toEqual [10201, 10404, 10609, 10816]

describe "A list containing the first 10 triangle numbers", ->
  list = List.range(1, 10).sums()

  it "should have 10 elements", ->
    expect(list.size()).toEqual 10

  it "should end with 55", ->
    expect(list.last()).toEqual 55

  it "should produce the correct list when multiplied with its reverse", ->
    test = List.fromArray([55,135,216,280,315])
    expect(list.times(list.reverse()).equals(test.concat(test.reverse())))
      .toBe true

  it """should produce the numbers 1,1,3,2,6,3,10,4,15,21,28,36,45,55
        when merged with the list 1,2,3,4""", ->
    expect(list.merge(List.range(1,4)).toArray())
      .toEqual [1,1,3,2,6,3,10,4,15,21,28,36,45,55]

describe "A list containing pairs (a,b) with a in 1,2 and b in 1,2,3", ->
  list = List.range(1, 2).cartesian List.range(1, 3)

  it "should have six elements", ->
    expect(list.size()).toBe 6

  it "should start with [1,1]", ->
    expect(list.first()).toEqual [1,1]

  it "should end with [2,3]", ->
    expect(list.last()).toEqual [2,3]

  it "should contain the expected elements", ->
    expect(list.toArray()).toEqual [[1,1], [1,2], [1,3], [2,1], [2,2], [2,3]]
