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

  it "should have an 's' at the second position", ->
    expect(list.get(1)).toBe 's'

  it "should have an 'd' at the third position", ->
    expect(list.get(2)).toBe 'd'

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

describe "A list containing the squares of the numbers from 101 to 110", ->
  list = List.range(101, 110).map((n) -> n * n)

  it "should start with 10201", ->
    expect(list.first()).toEqual 10201

  it "should end with 12100", ->
    expect(list.last()).toBe 12100

  it "should have 10 elements", ->
    expect(list.size()).toBe 10

  it "should have 6 elements larger than 11000", ->
    expect(list.drop_while((n) -> n <= 11000).size()).toBe 6

  it "should have 5 odd elements", ->
    expect(list.select((n) -> n % 2 == 1).size()).toBe 5
