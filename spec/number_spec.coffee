if typeof(require) != 'undefined'
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

  a = b = c = null

  check 0, -> num(0).sgn()
  check 0, -> num(0).cmp(0)

  check 1,      -> num(1).sgn()
  check true,   -> num(1).cmp(0) > 0
  check num(1), -> num(1).gcd(1)
  check num(0), -> num(1).times(0)

  check num(7), -> num(98).gcd 21
  check num(7), -> num(77777).gcd 21

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


  check num('-999999994999'), -> a = num -1e12 + 5001
  check num('5001'),          -> b = num 5001
  check num('999999995000'),  -> c = num 1e12 - 5000

  check '-999999994999', -> a.toString()
  check -1e12 + 5001,    -> a.toNative()
  check '999999995000',  -> c.toString()
  check 1e12 - 5000,     -> c.toNative()

  check true,  -> a.cmp(b) < 0
  check true,  -> a.lt b
  check true,  -> a.lt b.neg()
  check false, -> a.gt b
  check true,  -> a.neg().gt b

  check '-999999989998',    -> a.plus(b).toString()
  check num(-1e12 + 10002), -> a.plus b
  check '-1000000000000',   -> a.minus(b).toString()
  check num(-1e12),         -> a.minus b
  check '1000000000000',    -> b.minus(a).toString()
  check num(1e12),          -> b.minus a
  check '0',                -> a.minus(a).toString()
  check num(0),             -> a.minus a
  check '1',                -> a.plus(c).toString()
  check num(1),             -> a.plus c

  check '999999989998000025010001',
                            -> a.times(a).toString()
  check '999999979996000150060005499699940621500150020001',
                            -> (a.times a).times(a.times a).toString()

  check c,                   -> c.pow(3).idiv(c.times(c))
  check num(0),              -> c.pow(3).mod(c.times(c))
  check c,                   -> c.pow(3).plus(1).idiv(c.times(c))
  check num(1),              -> c.pow(3).plus(1).mod(c.times(c))
  check c.minus(1),          -> c.pow(3).minus(1).idiv(c.times(c))
  check c.times(c).minus(1), -> c.pow(3).minus(1).mod(c.times(c))

  faculty = (n) -> if n > 0 then faculty(n-1).times(n) else num 1

  check '30414093201713378043612608166064768844377641568960512000000000000',
    -> faculty(50).toString()

