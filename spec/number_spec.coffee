if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { equal }                 = require 'core_extensions'
  { num }                   = require 'number'
  { codeToString, classof } = require 'testing'
else
  { equal, num, codeToString, classof } = pazy

describe "An expression", ->
  check = (expected, expression) ->
    describe "given as #{codeToString expression}", ->
      seen = expression()
      it "should produce the #{classof expected} #{expected}", ->
        unless equal seen, expected
          throw new Error "Expected #{seen} to be #{expected}."
        expect(classof seen).toEqual classof expected

  check 0, -> num(0).sgn()
  check 0, -> num(0).cmp(0)

  check 1,      -> num(1).sgn()
  check true,   -> num(1).cmp(0) > 0
  check num(1), -> num(1).gcd(1)
  check num(0), -> num(1).times(0)

  check num(7), -> num(98).gcd 21
  check num(7), -> num(77777).gcd 21

  a = null
  check num(8192),  -> a = num Math.pow 2, 13
  check num(8194),  -> a.plus 2
  check num(8192),  -> a.times 1
  check num(16384), -> a.times 2
  check num(10192), -> a.plus 2000
  check 8192,       -> a.toNative()

  check num(1234512345), -> num(12345).times 100001
  check num(99999),      -> num(11111).times 9
  check num(3),          -> num(111).idiv 37
  check num(8),          -> num(119).mod 37

  check num(99),    -> num(9801).isqrt()
  check num(999),   -> num(998001).isqrt()
  check num(9999),  -> num(99980001).isqrt()

  check '2/3',           -> num.div(2, 3).toString()
  check num.div(3, 14),  -> num.div(9,10).times(num.div(5,21))
  check num.div(-2, 55), -> num.div(3,5).minus(num.div(7,11))
  check num.div(9, 2),   -> num.div 111111111, 12345679 * 2
  check num(3),          -> num.div(28,3).isqrt()
  check num(1),          -> num.div(1,2).plus num.div(1,2)
  check num(2),          -> num.div(2,3).plus num.div(4,3)
  check num.div(5, 3),   -> num.div(2,3).plus 1
  check num.div(1, 3),   -> num.div(2,3).div 2

  check 9999999999, -> num('99999999980000000001').isqrt().toNative()

  check num(-1234),                -> num '-1234'
  check '-123456789123456789',     -> num('-123456789123456789').toString()
  check num('199999999999999998'), -> x = num('99999999999999999'); x.plus x

  check num('123456789123456789'), -> a = num('123456789123456789')
  check num('200000000000000000'), -> a.plus num '76543210876543211'
  check num('123456789000006789'), -> a.minus 123450000
  check num('123456788999999999'), -> a.minus 123456790
  check num('123456789000000000'), -> a.minus 123456789
  check num('123456789000006789'), -> a.plus -123450000
  check num(0),                    -> a.minus a

describe "A number", ->
  describe """If a, b and c are long integers with
              a = -1e12 + 5001, b = 5001 and c = 1e12 - 5000""", ->
    a = num -1e12 + 5001
    b = num 5001
    c = num 1e12 - 5000
    one = num 1

    it "a should print as -999999994999", ->
      expect(a.toString()).toEqual '-999999994999'

    it "a should convert to the number -1e12 + 5001", ->
      expect(a.toNative()).toBe -1e12 + 5001

    it "b should print as 5001", ->
      expect(b.toString()).toEqual '5001'

    it "a should convert to the number 5001", ->
      expect(b.toNative()).toBe 5001

    it "c should print as 999999995000", ->
      expect(c.toString()).toEqual '999999995000'

    it "a should be smaller than b", ->
      expect(a.cmp(b)).toBeLessThan 0

    it "a should be smaller than -b", ->
      expect(a.cmp(b.neg())).toBeLessThan 0

    it "-a should be larger than b", ->
      expect(a.neg().cmp(b)).toBeGreaterThan 0

    it "c should convert to the number 1e12 - 5000", ->
      expect(c.toNative()).toBe 1e12 - 5000

    it "a + b should print as -999999989998", ->
      expect(a.plus(b).toString()).toEqual '-999999989998'

    it "a + b should convert to the number -1e12 + 10002", ->
      expect(a.plus(b).toNative()).toBe -1e12 + 10002

    it "a - b should print as -1000000000000", ->
      expect(a.minus(b).toString()).toEqual '-1000000000000'

    it "a - b should convert to the number -1e12", ->
      expect(a.minus(b).toNative()).toBe -1e12

    it "b - a should print as 1000000000000", ->
      expect(b.minus(a).toString()).toEqual '1000000000000'

    it "b - a should convert to the number 1e12", ->
      expect(b.minus(a).toNative()).toBe 1e12

    it "a - a should print as 0", ->
      expect(a.minus(a).toString()).toEqual '0'

    it "a - a should convert to the number 0", ->
      expect(a.minus(a).toNative()).toBe 0

    it "a + c should print as 1", ->
      expect(a.plus(c).toString()).toEqual '1'

    it "a + c should convert to the number 1", ->
      expect(a.plus(c).toNative()).toBe 1

    it "a * a should print as 999999989998000025010001", ->
      expect(a.times(a).toString()).toEqual "999999989998000025010001"

    it """(a * a) * (a * a) should print as
          999999979996000150060005499699940621500150020001""", ->
      expect((a.times a).times(a.times a).toString())
        .toEqual "999999979996000150060005499699940621500150020001"

    it "(c * c * c) / (c * c) should print as c", ->
      expect(c.times(c).times(c).idiv(c.times(c)).toString()).toEqual c.toString()

    it "(c * c * c) % (c * c) should print as 0", ->
      expect(c.times(c).times(c).mod(c.times(c)).toString()).toEqual "0"

    it "(c * c * c + 1) / (c * c) should print as c", ->
      expect(c.times(c).times(c).plus(one).idiv(c.times(c)).toString())
        .toEqual c.toString()

    it "(c * c * c + 1) % (c * c) should print as 1", ->
      expect(c.times(c).times(c).plus(one).mod(c.times(c)).toString()).toEqual "1"

    it "(c * c * c - 1) / (c * c) should print as c - 1", ->
      expect(c.times(c).times(c).minus(one).idiv(c.times(c)).toString())
        .toEqual c.minus(one).toString()

    it "(c * c * c - 1) % (c * c) should print as c * c - 1", ->
      expect(c.times(c).times(c).minus(one).mod(c.times(c)).toString())
        .toEqual c.times(c).minus(one).toString()
