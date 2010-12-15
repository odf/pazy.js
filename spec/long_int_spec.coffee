if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { LongIntegerClass } = require('long_int')
else
  { LongIntegerClass } = pazy

describe """If a, b and c are long integers with base 1e3;
            a = -1e12 + 501, b = 501 and c = 1e12 - 500""", ->
  BigNum = LongIntegerClass(3)
  a = new BigNum(-1e12 + 501)
  b = new BigNum(501)
  c = new BigNum(1e12 - 500)

  it "they all should have base 1000", ->
    expect(a.base()).toBe 1000
    expect(b.base()).toBe 1000
    expect(c.base()).toBe 1000

  it "a should print as -999_999_999_499 if '_' is set as the separator", ->
    expect(a.toString('_')).toEqual '-999_999_999_499'

  it "a should convert to the number -1e12 + 501", ->
    expect(a.toNumber()).toBe -1e12 + 501

  it "b should print as 501", ->
    expect(b.toString()).toEqual '501'

  it "a should convert to the number 501", ->
    expect(b.toNumber()).toBe 501

  it "c should print as 999_999_999_500 with '_' as the separator", ->
    expect(c.toString('_')).toEqual '999_999_999_500'

  it "c should convert to the number 1e12 - 500", ->
    expect(c.toNumber()).toBe 1e12 - 500

  it "a + b should print as -999_999_998_998 with '_' as the separator", ->
    expect(a.plus(b).toString('_')).toEqual '-999_999_998_998'

  it "a + b should convert to the number -1e12 + 1002", ->
    expect(a.plus(b).toNumber()).toBe -1e12 + 1002

  it "a - b should print as -1000000000000 if no separator is set", ->
    expect(a.minus(b).toString()).toEqual '-1000000000000'

  it "a - b should print as -1_000_000_000_000 with '_' as the separator", ->
    expect(a.minus(b).toString('_')).toEqual '-1_000_000_000_000'

  it "a - b should convert to the number -1e12", ->
    expect(a.minus(b).toNumber()).toBe -1e12

  it "b - a should print as 1000000000000 with no separator", ->
    expect(b.minus(a).toString()).toEqual '1000000000000'

  it "b - a should convert to the number 1e12", ->
    expect(b.minus(a).toNumber()).toBe 1e12

  it "a - a should print as 0", ->
    expect(a.minus(a).toString()).toEqual '0'

  it "a - a should convert to the number 0", ->
    expect(a.minus(a).toNumber()).toBe 0

  it "a + c should print as 1", ->
    expect(a.plus(c).toString()).toEqual '1'

  it "a + c should convert to the number 1", ->
    expect(a.plus(c).toNumber()).toBe 1
