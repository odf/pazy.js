if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { seq }     = require('sequence')
  { Dequeue } = require('dequeue')
else
  { seq, Dequeue } = pazy

describe "A dequeue", ->
  describe "A with the elements 0 to 9", ->
    dequeue = seq.reduce [0..9], new Dequeue(), (q, x) -> q.before(x)

    it "should have 10 elements", ->
      expect(dequeue.size()).toBe 10

    it "should start with a 0", ->
      expect(dequeue.first()).toBe 0

    it "should have 9 as its last element", ->
      expect(dequeue.last()).toBe 9

    it "should have a 1 right after the first element", ->
      expect(dequeue.rest().first()).toBe 1

    it "should have 9 elements after the first", ->
      expect(dequeue.rest().size()).toBe 9

    it "should have 9 elements before the last", ->
      expect(dequeue.rest().size()).toBe 9

    it "should have an 8 right before the last element", ->
      expect(dequeue.init().last()).toBe 8

    it "should have the same size after before() is called with no argument", ->
      expect(dequeue.before().size()).toBe 10

    it "should have the same size after after() is called with no argument", ->
      expect(dequeue.after().size()).toBe 10

  describe "with the elements 0 to 9 in reverse order", ->
    dequeue = seq.reduce [0..9], new Dequeue(), (q, x) -> q.after(x)

    it "should have 10 elements", ->
      expect(dequeue.size()).toBe 10

    it "should start with a 9", ->
      expect(dequeue.first()).toBe 9

    it "should have 0 as its last element", ->
      expect(dequeue.last()).toBe 0

    it "should have 9 elements after the first", ->
      expect(dequeue.rest().size()).toBe 9

    it "should have 9 elements before the last", ->
      expect(dequeue.rest().size()).toBe 9

    it "should have a 8 right after the first element", ->
      expect(dequeue.rest().first()).toBe 8

    it "should have an 1 right before the last element", ->
      expect(dequeue.init().last()).toBe 1
