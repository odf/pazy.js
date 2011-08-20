# A generic number type, currently supporting integral Javascript numbers,
# arbitrary precision integers and fractions.
#
# Arguments and results of arithmetic operations are coerced to the best
# fitting type.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# First, we import some necessary functions and data structures.

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { bounce } = require 'functional'
  { seq }    = require 'sequence'
else
  { bounce, seq } = this.pazy

# ----

# If this source file is being executed directly, run in test mode.

quicktest = module? and not module.parent
log = if quicktest then (str) -> console.log str else (str) ->

# ----

# An integer is represented as either a plain signed Javascript number with
# overflow (or strictly speaking: precision loss) checks or a lazy sequence of
# unsigned numbers. The constant `BASE` determines the number base for the
# latter representation. In addition, numbers with an absolute value smaller
# than `BASE` are represented as plain numbers.
#
# In production mode, the number `BASE` is computed as the largest power of 100
# that fits into a Javascript number twice with full precision. The number
# `HALFBASE` it its square root. According to the Javascript specification, we
# should expect `BASE == 10e14` and `HALFBASE == 10e7`.

BASE_LENGTH = if quicktest then 4 else
  seq.from(1)
    .map((n) -> 2 * n)
    .takeWhile((n) ->
      b = Math.pow 10, n
      2 * b - 2 != 2 * b - 1 and -2 * b + 2 != -2 * b + 1
    )
    .last()

BASE     = Math.pow 10, BASE_LENGTH
HALFBASE = Math.sqrt BASE

# ----

# Internal helpers for constructing number representations.

asNum = (n) ->
  if Math.abs(n) < BASE then new CheckedInt n else LongInt.fromNative n

# ----

# The `num` function provides the public interface.

num = (n = 0) ->
  switch typeof n
    when 'number'
      num.fromNative n
    when 'string'
      num.parse n
    else
      if n instanceof NumberBase
        n
      else
        throw new Error "expected a number, got #{n}"

num.fromNative = (n) ->
  throw new Error "expected an integer, got #{n}" unless n == Math.floor n
  asNum n

num.parse = (n) ->
  unless /^[+-]?\d+$/.test n
    throw new Error "expected an integer literal, got '#{n}'"

  [s, m] = switch n[0]
    when '-' then [-1, n[1..]]
    when '+' then [ 1, n[1..]]
    else          [ 1, n]

  if m.length <= BASE_LENGTH
    new CheckedInt parseInt n
  else
    parsed = (to) ->
      if to > 0
        from = Math.max 0, to - BASE_LENGTH
        seq.conj parseInt(m[from...to]), -> parsed from
      else
        null

    new LongInt s, parsed m.length


# ----

# The `NumberBase` class implements dispatching on binary arithmetic
# operators.

class NumberBase
  makeNum = (n) ->
    if n instanceof NumberBase
      n
    else if typeof n == 'number'
      if Math.floor(n) == n
        if Math.abs(n) < BASE
          new CheckedInt n
        else
          LongInt.fromNative n
      else
        throw new Error "expected an integer, got #{n}"
    else
      throw new Error "expected a number, got #{n}"

  upcast = (a, b) ->
    [op1, op2] = [makeNum(a), makeNum(b)]

    out =
      switch op1.constructor
        when LongInt
          switch op2.constructor
            when CheckedInt
              [op1, LongInt.fromNative(op2.val)]
            when LongInt
              [op1, op2]
        when CheckedInt
          switch op2.constructor
            when CheckedInt
              [op1, op2]
            when LongInt
              [LongInt.fromNative(op1.val), op2]

    if out
      out
    else
      [tp1, tp2] = [op1.constructor, op2.constructor]
      throw new Error "operands of types #{tp1} and #{tp2} not supported"

  @downcast: (x) ->
    if x instanceof LongInt and x.cmp(BASE) < 0
      if x.digits?
        new CheckedInt x.digits.first() * x.sign
      else
        new CheckedInt 0
    else
      x

  operator = (name, f) ->
    num[name]          = (args...) -> f.call num, args...
    NumberBase::[name] = (args...) -> num[name] this, args...

  for name in ['cmp', 'plus', 'minus', 'times', 'div', 'mod', 'gcd']
    do (name) ->
      namex = "#{name}__"
      operator name, (a, b) ->
        [x, y] = upcast a, b
        NumberBase.downcast x[namex] y

  gcd__: (other) ->
    step = (a, b) -> if b.isPos() then -> step b, a.mod(b) else a

    [x, y] = [@abs(), other.abs()]
    if x.cmp(y) > 0 then bounce step x, y else bounce step x, y

  for name in [
    'neg', 'abs', 'sgn', 'isPos', 'isNeg', 'isZero', 'isEven', 'isOdd'
  ]
    do (name) ->
      namex = "#{name}__"
      operator name, (a) -> makeNum(a)[namex]()

  operator 'sqrt', (a) -> NumberBase.downcast makeNum(a)['sqrt__']()

  operator 'pow', (a, b) ->
    step = (p, r, s) ->
      if s.isPos()
        if s.isOdd() > 0
          -> step p.times(r), r, s.minus 1
        else
          -> step p, r.times(r), s.div 2
      else
        p

    NumberBase.downcast bounce step makeNum(1), makeNum(a), makeNum(b)

# ----

# The `CheckInt` class provides integer operations with 'overflow checks'. In
# other words, if the result cannot be represented with full precision as a
# Javascript number, a `LongInt` is produced instead.

class CheckedInt extends NumberBase
  constructor: (@val = 0) ->

  neg__: -> new CheckedInt -@val

  abs__: -> new CheckedInt Math.abs @val

  sgn__: -> if @val < 0 then -1 else if @val > 0 then 1 else 0

  isPos__: -> @val > 0

  isNeg__: -> @val < 0

  isZero__: -> @val == 0

  isEven__: -> @val % 2 == 0

  isOdd__: -> @val % 2 != 0

  sqrt__: -> new CheckedInt Math.floor Math.sqrt @val

  cmp__: (other) ->
    if @val < other.val then -1 else if @val > other.val then 1 else 0

  plus__: (other) -> asNum @val + other.val

  minus__: (other) -> asNum @val - other.val

  times__: (other) ->
    x = @val * other.val
    if Math.abs(x) < BASE
      new CheckedInt x
    else
      LongInt.fromNative(@val).times other

  div__: (x) -> new CheckedInt Math.floor @val / x.val

  mod__: (x) -> new CheckedInt @val % x.val

  toString: -> "" + @val

# ----

# Here are the beginnings of the `LongInt` class.

class LongInt extends NumberBase
  constructor: (sign, @digits) ->
    @sign = if @digits? then sign else 0
    @first = @digits?.first() or 0

  neg__: -> new LongInt -@sign, @digits

  abs__: -> new LongInt 1, @digits

  sgn__: -> @sign

  isPos__: -> @sign > 0

  isNeg__: -> @sign < 0

  isZero__: -> @sign == 0

  isEven__: -> @first % 2 == 0

  isOdd__: -> @first % 2 != 0

  zeroes = BASE.toString()[1..]

  rdump = (s) ->
    if s
      s.map((t) -> "#{zeroes[t.toString().length..]}#{t}").into([]).join('|')
    else
      '[]'
  dump = (s) -> rdump s?.reverse()

  ZERO = seq [0]

  cleanup = (s) -> s?.reverse()?.dropWhile((x) -> x == 0)?.reverse() or null

  sqrt = (s) ->
    n = s.size()
    step = (r) ->
      rn = seq div(add(r, div(s, r)), seq([2]))
      if cmp(r, rn) then -> step(rn) else rn
    bounce step s.take n >> 1

  sqrt__: ->
    if @isZero()
      asNum 0
    else if @isPos()
      new LongInt 1, sqrt @digits
    else
      throw new Error "expected a non-negative number, got #{this}"

  cmp = (r, s) ->
    seq.sub(r, s)?.reverse()?.dropWhile((x) -> x == 0)?.first() or 0

  cmp__: (x) ->
    if @isZero()
      -x.sign
    else if x.isZero()
      @sign
    else if @sign != x.sign
      @sign
    else
      @sign * cmp @digits, x.digits

  add = (r, s, c = 0) ->
    if c or (r and s)
      [r_, s_] = [r or ZERO, s or ZERO]
      x = r_.first() + s_.first() + c
      [digit, carry] = if x >= BASE then [x - BASE, 1] else [x, 0]
      seq.conj(digit, -> add(r_.rest(), s_.rest(), carry))
    else
      s or r

  plus__: (x) ->
    if @sign != x.sign
      @minus x.neg()
    else
      new LongInt @sign, add @digits, x.digits

  sub = (r, s) ->
    step = (r, s, b = 0) ->
      if b or (r and s)
        [r_, s_] = [r or ZERO, s or ZERO]
        x = r_.first() - s_.first() - b
        [digit, borrow] = if x < 0 then [x + BASE, 1] else [x, 0]
        seq.conj(digit, -> step(r_.rest(), s_.rest(), borrow))
      else
        s or r
    cleanup step r, s

  minus__: (x) ->
    if @sign != x.sign
      @plus x.neg()
    else if cmp(@digits, x.digits) < 0
      new LongInt -@sign, sub x.digits, @digits
    else
      new LongInt @sign, sub @digits, x.digits

  split = (n) -> [n % HALFBASE, Math.floor n / HALFBASE]

  digitTimesDigit = (a, b) ->
    if b < BASE / a
      [a * b, 0]
    else
      [a0, a1] = split a
      [b0, b1] = split b
      [m0, m1] = split a0 * b1 + b0 * a1

      tmp = a0 * b0 + m0 * HALFBASE
      [lo, carry] = if tmp < BASE then [tmp, 0] else [tmp - BASE, 1]
      [lo, a1 * b1 + m1 + carry]

  seqTimesDigit = (s, d, c = 0) ->
    if c or s
      s_ = s or ZERO
      [lo, hi] = digitTimesDigit(d, s_.first())
      seq.conj(lo + c, -> seqTimesDigit(s_.rest(), d, hi))

  mul = (a, b) ->
    step = (r, a, b) ->
      if a
        t = add(r, seqTimesDigit(b, a.first())) or ZERO
        seq.conj(t.first(), -> step(t.rest(), a.rest(), b))
      else
        r
    step null, a, b

  times__: (x) -> new LongInt @sign * x.sign, mul @digits, x.digits

  divmod = (r, s) ->
    return [ZERO, ZERO] unless cleanup r

    scale = Math.floor BASE / (s.last() + 1)
    [r_, s_] = (seq seqTimesDigit(x, scale) for x in [r, s])
    [m, d] = [s_.size(), s_.last() + 1]

    step = (q, h, t) ->
      f = if h?.size() < m
        0
      else
        n = (h?.last() * if h?.size() > m then BASE else 1) or 0
        (Math.floor n / d) or (if cmp(h, s_) >= 0 then 1 else 0)

      if f
        -> step(add(q, seq.conj(f)), sub(h, seqTimesDigit(s_, f)), t)
      else if t
        -> step(seq.conj(0, -> q), seq.conj(t.first(), -> h), t.rest())
      else
        [cleanup(q), h && div(h, seq [scale])]

    bounce step null, null, r_?.reverse()

  div = (r, s) -> divmod(r, s)[0]

  mod = (r, s) -> divmod(r, s)[1]

  div__: (x) ->
    d = cmp @digits, x.digits
    if d < 0
      asNum 0
    else if d == 0
      asNum @sign * x.sign
    else
      new LongInt @sign * x.sign, div @digits, x.digits

  mod__: (x) ->
    d = cmp @digits, x.digits
    if d < 0
      this
    else if d == 0
      asNum 0
    else
      new LongInt @sign * x.sign, mod @digits, x.digits

  toString: ->
    parts = @digits?.reverse()?.dropWhile((d) -> d == 0)?.map (d) -> d.toString()
    if parts
      sign = if @isNeg() then '-' else ''
      rest = parts.rest()?.map (t) -> "#{zeroes[t.length..]}#{t}"
      sign + parts.first() + if rest? then rest.join '' else ''
    else
      '0'

  makeDigits = (m) ->
    if m then seq.conj m % BASE, -> makeDigits Math.floor(m / BASE) else null

  @fromNative: (n) ->
    if n < 0
      new LongInt -1, makeDigits -n
    else if n > 0
      new LongInt 1, makeDigits n
    else
      new LongInt 0, null

# ----
# Exporting.

exports ?= this.pazy ?= {}
exports.num = num

# ----

# Some quick tests.

if quicktest
  { show } = require 'testing'

  a = b = c = 0

  log ''
  show -> null
  show -> undefined

  log ''
  show -> num(98).gcd 21
  show -> num(77777).gcd 21

  log ''
  show -> a = num Math.pow 2, 13
  show -> LongInt.fromNative a.val
  show -> a.plus 2
  show -> a.times 1
  show -> a.times 2
  show -> a.plus 2000

  log ''
  show -> num -123456789000000
  show -> num '-1234'
  show -> num '-123456789000000'

  log ''
  show -> num(123456789).plus  876543211
  show -> num(123456789).minus 123450000
  show -> num(123456789).minus 123456790
  show -> num(123456789).minus 123456789
  show -> num(123456789).plus -123450000

  log ''
  show -> num(12345).times 100001
  show -> num(11111).times 9
  show -> num(111).div 37
  show -> num(111111).div 37
  show -> num(111111111).div 37
  show -> num(111111111).div 12345679
  show -> num(99980001).div 49990001
  show -> num(20001).div 10001

  log ''
  show -> num(111).mod 37
  show -> num(111112).mod 37
  show -> num(111111111).mod 12345679

  log ''
  show -> num(9801).sqrt()
  show -> num(998001).sqrt()
  show -> num(99980001).sqrt()

  log ''
  show -> num(10).pow 6
  show -> num(2).pow 16

  log ''
  show -> num.plus 123456789, 876543211
  show -> num.sqrt 99980001
  show -> num.pow 2, 16
  show -> num.abs -12345
  show -> num.isZero 1
  show -> num.isZero 123456
  show -> num.isZero 0
  show -> num.isNeg 0
  show -> num.isNeg -45
  show -> num.isNeg -12345
  show -> num.isOdd -12345
