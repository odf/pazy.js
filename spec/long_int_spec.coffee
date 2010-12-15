if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { LongInt } = require('long_int')
else
  { LongInt } = pazy


describe "If a = -1e12 + 501, b = 501, c = 1e12 - 500", ->
  a = new LongInt(-1e12 + 501)
  b = new LongInt(501)
  c = new LongInt(1e12 - 500)

  it "a should print as -999999999499", ->
    expect(a.toString()).toEqual '-999999999499'

  it "a should convert to the number -1e12 + 501", ->
    expect(a.toNumber()).toBe -1e12 + 501

  it "b should print as 501", ->
    expect(b.toString()).toEqual '501'

  it "a should convert to the number 501", ->
    expect(b.toNumber()).toBe 501

  it "c should print as 999999999500", ->
    expect(c.toString()).toEqual '999999999500'

  it "c should convert to the number 1e12 - 500", ->
    expect(c.toNumber()).toBe 1e12 - 500

  it "a + b should print as -999999998998", ->
    expect(a.plus(b).toString()).toEqual '-999999998998'

  it "a + b should convert to the number -1e12 + 1002", ->
    expect(a.plus(b).toNumber()).toBe -1e12 + 1002

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
