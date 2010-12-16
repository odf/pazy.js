if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { LongInt } = require('long_int')
else
  { LongInt } = pazy

describe """If a, b and c are long integers with base 10000;
            a = -1e12 + 5001, b = 5001 and c = 1e12 - 5000""", ->
  LongInt.digit_size__ 4
  a = new LongInt -1e12 + 5001
  b = new LongInt 5001
  c = new LongInt 1e12 - 5000

  it "a should print as -999999994999", ->
    expect(a.toString()).toEqual '-999999994999'

  it "a should convert to the number -1e12 + 5001", ->
    expect(a.toNumber()).toBe -1e12 + 5001

  it "b should print as 5001", ->
    expect(b.toString()).toEqual '5001'

  it "a should convert to the number 5001", ->
    expect(b.toNumber()).toBe 5001

  it "c should print as 999999995000", ->
    expect(c.toString()).toEqual '999999995000'

  it "a should be smaller than b", ->
    expect(a.cmp(b)).toBeLessThan 0

  it "a should be smaller than -b", ->
    expect(a.cmp(b.neg())).toBeLessThan 0

  it "-a should be larger than b", ->
    expect(a.neg().cmp(b)).toBeGreaterThan 0

  it "c should convert to the number 1e12 - 5000", ->
    expect(c.toNumber()).toBe 1e12 - 5000

  it "a + b should print as -999999989998", ->
    expect(a.plus(b).toString()).toEqual '-999999989998'

  it "a + b should convert to the number -1e12 + 10002", ->
    expect(a.plus(b).toNumber()).toBe -1e12 + 10002

  it "a - b should print as -1000000000000", ->
    expect(a.minus(b).toString()).toEqual '-1000000000000'

  it "a - b should convert to the number -1e12", ->
    expect(a.minus(b).toNumber()).toBe -1e12

  it "b - a should print as 1000000000000", ->
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
