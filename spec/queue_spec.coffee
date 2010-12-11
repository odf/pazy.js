if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Stream } = require('stream')
  { Queue }  = require('queue')
else
  { Stream } = pazy
  { Queue }  = pazy


describe "A queue with the elements 0 to 9", ->
  queue = Stream.from(0).accumulate(new Queue(), (q, x) -> q.push(x)).get(9)

  it "should start with a 0", ->
    expect(queue.first()).toBe 0

  it "should have 9 as its last element", ->
    t = queue
    t = t.rest() while t.rest()?.first()
    expect(t.first()).toBe 9
