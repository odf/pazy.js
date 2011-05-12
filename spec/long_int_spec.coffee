if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { LongInt } = require('long_int')
else
  { LongInt } = pazy


describe "A LongInt with value 0", ->
  a = new LongInt 0

  it "should have a positive sign", ->
    expect(a.sign()).toEqual 1

  it "can be compared with 0", ->
    expect(a.cmp(0)).toBe 0


describe "A LongInt with value 1", ->
  a = new LongInt 1

  it "should have a positive sign", ->
    expect(a.sign()).toEqual 1

  it "can be compared with 0", ->
    expect(a.cmp(0)).toBeGreaterThan 0

  it "can have the gcd taken with itself", ->
    expect(a.gcd(a).toString()).toEqual '1'

  it "can be multiplied by 0", ->
    expect(a.times(0).toString()).toEqual '0'


describe "A LongInt", ->
  a = new LongInt 12345679

  it "can have its sign changed", ->
    expect(a.neg().toString()).toEqual '-12345679'

  it "can have its absolute value taken", ->
    expect(a.abs().toString()).toEqual '12345679'
    expect(a.neg().abs().toString()).toEqual '12345679'

  it "can have its sign determined", ->
    expect(a.sign()).toBe 1
    expect(a.neg().sign()).toBe -1

  it "can be compared with an integer", ->
    expect(a.cmp(12345680)).toBeLessThan 0

  it "can be compared with 0", ->
    expect(a.cmp(0)).toBeGreaterThan 0

  it "can be compared with another LongInt", ->
    expect(a.cmp(new LongInt 12345680)).toBeLessThan 0

  it "can have an integer added to it", ->
    expect(a.plus(87654320).toString()).toEqual '99999999'

  it "can have another LongInt added to it", ->
    expect(a.plus(new LongInt 87654320).toString()).toEqual '99999999'

  it "can have an integer subtracted from it", ->
    expect(a.minus(4445).toString()).toEqual '12341234'

  it "can have another LongInt subtracted from it", ->
    expect(a.minus(new LongInt 4445).toString()).toEqual '12341234'

  it "can be multiplied with an integer", ->
    expect(a.times(9000000009).toString()).toEqual '111111111111111111'

  it "can be multiplied with another LongInt", ->
    expect(a.times(new LongInt 9000000009).toString())
      .toEqual '111111111111111111'

  it "can be multiplied by 0", ->
    expect(a.times(0).toString()).toEqual '0'

  it "can be divided by an integer", ->
    expect(a.div(343).toString()).toEqual '35993'

  it "can be divided by another LongInt", ->
    expect(a.div(new LongInt 343).toString()).toEqual '35993'

  it "can be taken modulo an integer", ->
    expect(a.mod(343).toString()).toEqual '80'

  it "can be taken modulo another LongInt", ->
    expect(a.mod(new LongInt 343).toString()).toEqual '80'

  it "can be taken to an integer power", ->
    expect(a.pow(5).toString()).toEqual '286797197645258138803977054387424399'
    expect(a.pow(4).toString()).toEqual '23230573032496482275618623681'

  it "can be taken to a LongInt power", ->
    expect(a.pow(new LongInt 5).toString())
      .toEqual '286797197645258138803977054387424399'
    expect(a.pow(new LongInt 4).toString())
      .toEqual '23230573032496482275618623681'

  it "can be taken the square root of", ->
    expect(a.sqrt().toString()).toEqual '3513'
    expect(a.pow(4).sqrt().toString()).toEqual a.pow(2).toString()


describe """If a, b and c are long integers with
            a = -1e12 + 5001, b = 5001 and c = 1e12 - 5000""", ->
  a = new LongInt -1e12 + 5001
  b = new LongInt 5001
  c = new LongInt 1e12 - 5000
  one = new LongInt 1

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

  it "a * a should print as 999999989998000025010001", ->
    expect(a.times(a).toString()).toEqual "999999989998000025010001"

  it """(a * a) * (a * a) should print as
        999999979996000150060005499699940621500150020001""", ->
    expect((a.times a).times(a.times a).toString())
      .toEqual "999999979996000150060005499699940621500150020001"

  it "(c * c * c) / (c * c) should print as c", ->
    expect(c.times(c).times(c).div(c.times(c)).toString()).toEqual c.toString()

  it "(c * c * c) % (c * c) should print as 0", ->
    expect(c.times(c).times(c).mod(c.times(c)).toString()).toEqual "0"

  it "(c * c * c + 1) / (c * c) should print as c", ->
    expect(c.times(c).times(c).plus(one).div(c.times(c)).toString())
      .toEqual c.toString()

  it "(c * c * c + 1) % (c * c) should print as 1", ->
    expect(c.times(c).times(c).plus(one).mod(c.times(c)).toString()).toEqual "1"

  it "(c * c * c - 1) / (c * c) should print as c - 1", ->
    expect(c.times(c).times(c).minus(one).div(c.times(c)).toString())
      .toEqual c.minus(one).toString()

  it "(c * c * c - 1) % (c * c) should print as c * c - 1", ->
    expect(c.times(c).times(c).minus(one).mod(c.times(c)).toString())
      .toEqual c.times(c).minus(one).toString()
