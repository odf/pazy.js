if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence }               = require('sequence')
  { CountedSeq, OrderedSeq } = require('finger_tree')
else
  { Sequence, CountedSeq, OrderedSeq } = pazy

asSeq = (x) -> x.reduceRight ((a, b) -> Sequence.conj a, -> b), null
sum   = (x) -> x.reduceLeft 0, (a, b) -> a + b

leftSeq  = (t) ->
  Sequence.conj(t.first(), -> leftSeq t.rest()) unless t.isEmpty()

rightSeq = (t) ->
  Sequence.conj(t.last(), -> rightSeq t.init()) unless t.isEmpty()

asArray  = (t) -> Sequence.into leftSeq(t), []


describe "A finger tree containing a single element", ->
  tree = CountedSeq.buildRight 1

  it "should have size 1", ->
    expect(tree.size()).toBe 1

  #TODO implementation specific - remove after debugging
  it "should bee implemented as a Single node", ->
    expect(tree.data.constructor.name).toEqual "Single"


describe "A finger tree made by prepending elements from a sequence", ->
  tree = CountedSeq.buildRight [1..10]...

  it "should have the right size", ->
    expect(tree.size()).toBe 10

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

  it "should produce correct sizes while being deconstructed", ->
    expect(tree.init().measure()).toBe 9
    expect(tree.rest().measure()).toBe 9
    expect(tree.init().init().measure()).toBe 8
    expect(tree.init().rest().measure()).toBe 8
    expect(tree.rest().init().measure()).toBe 8
    expect(tree.rest().rest().measure()).toBe 8

  it "within a finger tree should not lead to confusion with measures", ->
    expect(CountedSeq.buildRight(tree, tree).measure()).toBe 2

  it "should split correctly in the middle", ->
    [l, x, r] = tree.split (n) -> n > 5
    expect(asArray l).toEqual [10..6]
    expect(x).toBe 5
    expect(asArray r).toEqual [4..1]

  it "should split correctly at the end", ->
    [l, x, r] = tree.split (n) -> n > 10
    expect(asArray l).toEqual [10..1]
    expect(x).toBe undefined
    expect(asArray r).toEqual []

  it "should do takeUntil correctly", ->
    expect(asArray tree.takeUntil (n) -> n > 7).toEqual [10..4]

  it "should do dropUntil correctly", ->
    expect(asArray tree.dropUntil (n) -> n > 4).toEqual [6..1]

  it "should return the element at position 7 as 3", ->
    expect(tree.find (n) -> n > 7).toBe 3

  it "should respond to get", ->
    expect(tree.get(8)).toBe 2

  it "should respond to splitAt", ->
    [l, r] = tree.splitAt 6
    expect(asArray l).toEqual [10..5]
    expect(asArray r).toEqual [4..1]


describe "A finger tree made by appending elements from a sequence", ->
  tree = CountedSeq.buildLeft [1..100]...

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
    expect(asArray(tree.concat CountedSeq.buildLeft())).toEqual [1..100]

  it "should concatenate with an empty one on the left", ->
    expect(asArray(CountedSeq.buildLeft().concat tree)).toEqual [1..100]

  it "should concatenate with a single-element one on the right", ->
    expect(asArray(tree.concat CountedSeq.buildLeft 101)).toEqual [1..101]

  it "should concatenate with a single-element one on the left", ->
    expect(asArray(CountedSeq.buildLeft(0).concat tree)).toEqual [0..100]

  it "should have the right size", ->
    expect(tree.measure()).toBe 100

  it "should split correctly", ->
    [l, x, r] = tree.split (n) -> n > 27
    expect(asArray l).toEqual [1..27]
    expect(x).toBe 28
    expect(asArray r).toEqual [29..100]


describe "An ordered sequence", ->
  tree = Sequence.reduce [8, 3, 4, 2, 0, 1, 7, 5, 6, 9], OrderedSeq.buildLeft(), (s, x) -> s.insert x

  it "should have the right elements in the right order", ->
    expect(asArray tree).toEqual [0..9]

  it "should partition correctly", ->
    [l, r] = tree.partition 6
    expect(asArray l).toEqual [0, 1, 2, 3, 4, 5]
    expect(asArray r).toEqual [6, 7, 8, 9]

  it "should split correctly", ->
    [l, x, r] = tree.split (m) -> m > 6
    expect(asArray l).toEqual [0, 1, 2, 3, 4, 5, 6]
    expect(x).toBe 7
    expect(asArray r).toEqual [8, 9]

  it "should have the right contents after removing some elements", ->
    t = tree.deleteAll(5).deleteAll(7).deleteAll(2)
    expect(asArray t).toEqual [0, 1, 3, 4, 6, 8, 9]
