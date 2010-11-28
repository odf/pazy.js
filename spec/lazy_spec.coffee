if typeof(require) != 'undefined'
  require.paths.unshift './lib'
  suspend = require('lazy').suspend
else
  suspend = pazy.suspend


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
