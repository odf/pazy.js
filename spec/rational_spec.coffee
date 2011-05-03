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

  it "can be multiplied with another rational", ->
    expect(a.times(new Rational(21, 2)).toString()).toEqual '15/2'
