if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
  { reduceRight, reduceLeft, Empty } = require('finger_tree')
else
  { Sequence, reduceRight, reduceLeft, Empty } = pazy


asSeq = (x) -> reduceRight((a, b) -> Sequence.conj a, -> b) x, null
sum   = (x) -> reduceLeft((a, b) -> a + b) 0, x


describe "A finger tree made by prepending elements from a sequence", ->
  tree = Sequence.reduce [1..10], Empty, (s, a) -> s.after a

  it "should have the right elements in the right order", ->
    expect(asSeq(tree).into []).toEqual [10..1]

  it "should add up to 55", ->
    expect(sum(tree)).toBe 55

describe "A finger tree made by appending elements from a sequence", ->
  tree = Sequence.reduce [1..10], Empty, (s, a) -> s.before a

  it "should have the right elements in the right order", ->
    expect(asSeq(tree).into []).toEqual [1..10]

  it "should add up to 55", ->
    expect(sum(tree)).toBe 55
