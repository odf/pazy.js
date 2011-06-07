if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
  { reduceRight, reduceLeft, Empty } = require('finger_tree')
else
  { Sequence, reduceRight, reduceLeft, Empty } = pazy


asSeq = (x) -> reduceRight((a, b) -> Sequence.conj a, -> b) x, null
sum   = (x) -> reduceLeft((a, b) -> a + b) 0, x

leftSeq = (t) -> if t != Empty then Sequence.conj t.first(), -> leftSeq t.rest()
rightSeq = (t) -> if t != Empty then Sequence.conj t.last(), -> rightSeq t.init()


describe "A finger tree made by prepending elements from a sequence", ->
  tree = Sequence.reduce [1..10], Empty, (s, a) -> s.after a

  it "should have the right elements in the right order", ->
    expect(asSeq(tree).into []).toEqual [10..1]

  it "should add up to 55", ->
    expect(sum(tree)).toBe 55

  it "should have 10 as its first element", ->
    expect(tree.first()).toBe 10

  it "should have 1 as its last element", ->
    expect(tree.last()).toBe 1

  it "should produce the elements in order via first|rest", ->
    expect(leftSeq(tree).into []).toEqual [10..1]

  it "should produce the elements in reverse order via last|init", ->
    expect(rightSeq(tree).into []).toEqual [1..10]

describe "A finger tree made by appending elements from a sequence", ->
  tree = Sequence.reduce [1..100], Empty, (s, a) -> s.before a

  it "should have the right elements in the right order", ->
    expect(asSeq(tree).into []).toEqual [1..100]

  it "should add up to 5050", ->
    expect(sum(tree)).toBe 5050

  it "should have 1 as its first element", ->
    expect(tree.first()).toBe 1

  it "should have 100 as its last element", ->
    expect(tree.last()).toBe 100

  it "should produce the elements in order via first|rest", ->
    expect(leftSeq(tree).into []).toEqual [1..100]

  it "should produce the elements in reverse order via last|init", ->
    expect(rightSeq(tree).into []).toEqual [100..1]
