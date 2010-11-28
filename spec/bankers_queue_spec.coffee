if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  Stream = require('stream').Stream
  Queue  = require('bankers_queue').Queue
else
  Stream = pazy.Stream
  Queue  = pazy.Queue


describe "A queue with the elements 0 to 9", ->
  queue = Stream.from(0).accumulate(new Queue(), (q, x) -> q.push(x)).get(9)

  it "should have size 10", ->
    expect(queue.size).toBe 10

  it "should start with a 0", ->
    expect(queue.first).toBe 0

  it "should have 9 as its last element", ->
    t = queue
    while t.size > 1
      t = t.rest()
    expect(t.first).toBe 9
