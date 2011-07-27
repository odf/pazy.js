if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { seq }   = require('sequence')
  { Stack } = require('stack')
else
  { seq, Stack } = pazy


describe "A stack with the elements 0 to 9", ->
  stack = seq.reduce [0..9], new Stack(), (q, x) -> q.push(x)

  it "should start with a 9", ->
    expect(stack.first()).toBe 9

  it "should have 0 as its last element", ->
    t = stack
    t = t.rest() while t.rest()?.first()?
    expect(t.first()).toBe 0

  it "should produce the right sequence", ->
    expect(seq.into stack, []).toEqual [9..0]
