if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { seq }   = require('sequence')
  { Queue } = require('queue')
else
  { seq }   = pazy
  { Queue } = pazy


describe "A queue with the elements 0 to 9", ->
  queue = seq.reduce [0..9], new Queue(), (q, x) -> q.push(x)

  it "should start with a 0", ->
    expect(queue.first()).toBe 0

  it "should have 9 as its last element", ->
    t = queue
    t = t.rest() while t.rest()?.first()?
    expect(t.first()).toBe 9
