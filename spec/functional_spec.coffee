if typeof(require) != 'undefined'
  { suspend, bounce, scope } = require('functional')
else
  { suspend, bounce, scope } = pazy

describe """The suspension of a function that increments
            a counter and returns its new value""", ->
  counter = 0
  f = null

  beforeEach -> f = suspend(-> counter += 1)

  it "should increment the current counter value when first called", ->
    counter = 5
    expect(f()).toBe 6
    expect(counter).toBe 6

  it """should ignore the counter and return the
        previous value on subsequent calls""", ->
    counter = 5
    expect(f()).toBe 6
    counter = 9
    expect(f()).toBe 6
    expect(counter).toBe 9


describe "A function computing the factorial via simulated tail recursion", ->
  factorial = (n) ->
    fac = (n, p) -> if n then -> fac(n-1, p * n) else p
    bounce fac(n, 1)

  it "should print 5040 when applied to 7", ->
    expect(factorial(7)).toBe 5040


describe "A function containing a local inner scope within a loop", ->
  f = ->
    log = []
    a = ['nul', 'one', 'two', 'tri']
    for i in [1..3]
      s = a[i]
      log.push [i, s]
      scope [i+2, "(#{s})"], (i, s) ->
        log.push [i, s]
        [i, s] = [i * i, s.toUpperCase()]
        log.push [i, s]
      log.push [i, s]
    log

  it "should restore outer values after leaving the inner scope", ->
    expect(f()).toEqual [
      [1, "one"], [3, "(one)"], [ 9, "(ONE)"], [1, "one"],
      [2, "two"], [4, "(two)"], [16, "(TWO)"], [2, "two"],
      [3, "tri"], [5, "(tri)"], [25, "(TRI)"], [3, "tri"]
    ]
