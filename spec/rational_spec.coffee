if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Rational } = require('rational')
else
  { Rational } = pazy


describe 'A Rational', ->
  a = new Rational(5, 7)

  it "can have its sign changed", ->
    expect(a.neg().toString()).toEqual '-5/7'

  it "can be inverted after having its sign changed", ->
    expect(a.neg().inv().toString()).toEqual '-7/5'

  it "can have its absolute value taken", ->
    expect(a.abs().toString()).toEqual '5/7'
    expect(a.neg().abs().toString()).toEqual '5/7'

  it "can have its sign determined", ->
    expect(a.sign()).toBe 1
    expect(a.neg().sign()).toBe -1

  it "can be added to another rational", ->
    expect(a.plus(new Rational(-2, 3)).toString()).toEqual '1/21'

  it "can be subtracted from another rational", ->
    expect(new Rational(5).minus(a).toString()).toEqual '30/7'

  it "can be subtracted from itself", ->
    expect(a.minus(a).toString()).toEqual '0/1'

  it "can be compared to another rational", ->
    expect(a.cmp new Rational 5).toBeLessThan 0

  it "can be compared to itself", ->
    expect(a.cmp a).toBe 0

  it "can be multiplied with another rational", ->
    expect(a.times(new Rational(21, 2)).toString()).toEqual '15/2'

  it "can be divided by another rational", ->
    expect(a.div(new Rational(21, 14)).toString()).toEqual '10/21'

  it "can be taken to a positive integer power", ->
    expect(a.pow(7).toString()).toEqual '78125/823543'

describe 'A Rational with the value 0', ->
  a = new Rational(0)

  it "can be negated", ->
    expect(a.neg().toString()).toBe '0/1'

  it "can have itself added to it", ->
    expect(a.plus(a).toString()).toBe '0/1'

  it "can have itself subtracted from it", ->
    expect(a.minus(a).toString()).toBe '0/1'

  it "can be compared to 0", ->
    expect(a.cmp 0).toBe 0
