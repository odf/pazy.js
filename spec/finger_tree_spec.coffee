if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
  { reduceRight, reduceLeft, makeNode, makeDigit,
    Empty, Single, Deep } = require('finger_tree')
else
  { Sequence, reduceRight, reduceLeft, makeNode, makeDigit,
    Empty, Single, Deep } = pazy


asSeq = (x) -> reduceRight((a, b) -> Sequence.conj a, -> b) x, null
sum   = (x) -> reduceLeft((a, b) -> a + b) 0, x


describe "A digit with three elements", ->
  dig = makeDigit 1, 2, 3

  it "should have the right elements in the right order", ->
    expect(asSeq(dig).into []).toEqual [1,2,3]

  it "should add up to 6", ->
    expect(sum(dig)).toBe 6

describe "A digit with four elements", ->
  dig = makeDigit 1, 2, 3, 4

  it "should have the right elements in the right order", ->
    expect(asSeq(dig).into []).toEqual [1,2,3,4]

  it "should add up to 10", ->
    expect(sum(dig)).toBe 10

describe "A deep node with a total of 10 entries", ->
  left  = makeDigit 1, 2, 3
  mid   = new Deep makeDigit(makeNode 4,5), Empty, makeDigit(makeNode 6,7)
  right = makeDigit 8, 9, 10

  tree = new Deep left, mid, right

  it "should have the right elements in the right order", ->
    expect(asSeq(tree).into []).toEqual [1..10]

  it "should add up to 55", ->
    expect(sum(tree)).toBe 55

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
