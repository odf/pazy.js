if typeof(require) != 'undefined'
  { seq }                   = require('sequence')
  { CountedSeq, SortedSeq } = require('finger_tree')
else
  { seq, CountedSeq, SortedSeq } = pazy

sum   = (x) -> x.reduceLeft 0, (a, b) -> a + b

leftSeq  = (t) -> seq.conj(t.first(), -> leftSeq t.rest()) unless t.isEmpty()

rightSeq = (t) -> seq.conj(t.last(), -> rightSeq t.init()) unless t.isEmpty()

asArray  = (t) -> seq.into t, []


describe "A finger tree containing a single element", ->
  tree = CountedSeq.build 1

  it "should have size 1", ->
    expect(tree.size()).toBe 1


describe "A finger tree made by prepending elements from a sequence", ->
  tree = seq.reduce [1..10], CountedSeq.build(), (s, x) -> s.after x

  it "should have the right size", ->
    expect(tree.size()).toBe 10

  it "should have the right elements in the right order", ->
    expect(asArray tree).toEqual [10..1]

  it "should have the correct reverse", ->
    expect(asArray tree.reverse()).toEqual [1..10]

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
    expect(CountedSeq.build(tree, tree).measure()).toBe 2

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
  tree = CountedSeq.build [1..100]...

  it "should have the right elements in the right order", ->
    expect(asArray tree).toEqual [1..100]

  it "should have the correct reverse", ->
    expect(asArray tree.reverse()).toEqual [100..1]

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
    expect(asArray(tree.concat CountedSeq.build())).toEqual [1..100]

  it "should concatenate with an empty one on the left", ->
    expect(asArray(CountedSeq.build().concat tree)).toEqual [1..100]

  it "should concatenate with a single-element one on the right", ->
    expect(asArray(tree.concat CountedSeq.build 101)).toEqual [1..101]

  it "should concatenate with a single-element one on the left", ->
    expect(asArray(CountedSeq.build(0).concat tree)).toEqual [0..100]

  it "should have the right size", ->
    expect(tree.measure()).toBe 100

  it "should split correctly", ->
    [l, x, r] = tree.split (n) -> n > 27
    expect(asArray l).toEqual [1..27]
    expect(x).toBe 28
    expect(asArray r).toEqual [29..100]


describe "A sorted sequence", ->
  tree = SortedSeq.build 8, 3, 4, 2, 0, 1, 7, 5, 6, 9

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

describe "A pair of sorted sequences", ->
  t1 = SortedSeq.build 8, 5, 7, 9, 1, 6
  t2 = SortedSeq.build 4, 7, 2, 0, 3, 1

  it "should merge correctly", ->
    expect(asArray t1.merge(t2)).toEqual [0, 1, 1, 2, 3, 4, 5, 6, 7, 7, 8, 9]

  it "should intersect correctly", ->
    expect(asArray t1.intersect(t2)).toEqual [1, 7]

describe "A pair of single-element sorted sequences", ->
  t1 = SortedSeq.build 8
  t2 = SortedSeq.build 4

  it "should merge correctly", ->
    expect(asArray t1.merge(t2)).toEqual [4, 8]

  it "should intersect correctly", ->
    expect(asArray t1.intersect(t2)).toEqual []
