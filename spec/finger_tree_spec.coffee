if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
  { Empty }    = require('finger_tree')
else
  { Sequence, Empty } = pazy


asSeq = (x) -> x.reduceRight ((a, b) -> Sequence.conj a, -> b), null
sum   = (x) -> x.reduceLeft 0, (a, b) -> a + b

leftSeq  = (t) -> if t != Empty then Sequence.conj t.first(), -> leftSeq t.rest()
rightSeq = (t) -> if t != Empty then Sequence.conj t.last(), -> rightSeq t.init()
asArray  = (t) -> leftSeq(t).into []

describe "A finger tree made by prepending elements from a sequence", ->
  tree = Sequence.reduce [1..10], Empty, (s, a) -> s.after a

  it "should have the right elements in the right order", ->
    expect(asArray tree).toEqual [10..1]

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

  it "should have the right size", ->
    expect(tree.measure()).toBe 10

describe "A finger tree made by appending elements from a sequence", ->
  tree = Sequence.reduce [1..100], Empty, (s, a) -> s.before a

  it "should have the right elements in the right order", ->
    expect(asArray tree).toEqual [1..100]

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

  it "should concatenate with itself properly", ->
    expect(asArray(tree.concat tree)).toEqual [1..100].concat [1..100]

  it "should concatenate with an empty one on the right", ->
    expect(asArray(tree.concat Empty)).toEqual [1..100]

  it "should concatenate with an empty one on the left", ->
    expect(asArray(Empty.concat tree)).toEqual [1..100]

  it "should concatenate with a single-element one on the right", ->
    expect(asArray(tree.concat Empty.before 101)).toEqual [1..101]

  it "should concatenate with an empty one on the left", ->
    expect(asArray(Empty.before(0).concat tree)).toEqual [0..100]

  it "should have the right size", ->
    expect(tree.measure()).toBe 100
