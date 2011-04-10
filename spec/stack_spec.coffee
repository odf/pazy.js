if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
  { Stack }    = require('stack')
else
  { Sequence } = pazy
  { Stack }    = pazy


describe "A stack with the elements 0 to 9", ->
  stack = Sequence.reduce [0..9], new Stack(), (q, x) -> q.push(x)

  it "should start with a 0", ->
    expect(stack.first()).toBe 9

  it "should have 9 as its last element", ->
    t = stack
    t = t.rest() while t.rest()?.first()?
    expect(t.first()).toBe 0
