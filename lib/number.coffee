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
  { trampoline } = require 'functional'
  { seq }  = require 'sequence'
else
  { trampoline, seq } = this.pazy

# ----

# If this source file is being executed directly, run in test mode.

quicktest = module? and not module.parent
log = if quicktest then (str) -> console.log str else (str) ->

# Some helper functions for debugging.

rdump = (s) -> "#{if s then s.into([]).join('|') else '[]'}"
dump = (s) -> rdump s?.reverse()

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

  downcast = (x) ->
    if x instanceof LongInt and x.cmp(BASE) < 0
      new CheckedInt x.digits.first() * x.sign
    else
      x

  operator = (name, f) ->
    NumberBase[name]   = (args...) -> f.call NumberBase, args...
    NumberBase::[name] = (args...) -> NumberBase[name] this, args...

  for name in ['cmp', 'plus', 'minus', 'times', 'div', 'mod', 'gcd']
    do (name) ->
      namex = "#{name}__"
      operator name, (a, b) ->
        [x, y] = upcast a, b
        downcast x[namex] y


# ----

# The `CheckInt` class provides integer operations with 'overflow checks'. In
# other words, if the result cannot be represented with full precision as a
# Javascript number, a `LongInt` is produced instead.

class CheckedInt extends NumberBase
  getval = (x) ->
    if x instanceof CheckedInt
      x.val
    else if typeof x == 'number'
      if Math.floor(x) == x
        x
      else
        throw new Error "expected an integer, got #{n}"
    else
      throw new Error "expected a number, got #{n}"

  constructor: (@val = 0) ->

  neg: -> new CheckedInt -@val

  abs: -> new CheckedInt Math.abs @val

  sgn: -> if @val < 0 then -1 else if @val > 0 then 1 else 0

  sqrt: -> new CheckedInt Math.floor Math.sqrt @val

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

  div: (other) -> new CheckedInt Math.floor @val / getval other

  mod: (other) -> new CheckedInt @val % getval other

  gcd: (other) ->
    step = (a, b) -> if b > 0 then -> step b, a % b else a

    [a, b] = [Math.abs(@val), Math.abs(getval other)]
    new CheckedInt if a > b then trampoline step a, b else trampoline step b, a

  toString: -> "" + @val

# ----

# Here are the beginnings of the `LongInt` class.

class LongInt extends NumberBase
  constructor: (@sign = 0, @digits = null) ->

  neg: -> new LongInt -@sign, @digits

  abs: -> new LongInt 1, @digits

  sgn: -> @sign

  cmp = (r, s) ->
    seq.sub(r, s)?.reverse()?.dropWhile((x) -> x == 0)?.first() or 0

  cmp__: (x) ->
    if @sign == 0
      -x.sign
    else if x.sign == 0
      @sign
    else if @sign != x.sign
      @sign
    else
      @sign * cmp @digits, x.digits

  ZERO = seq [0]
  ONE  = seq [1]
  TWO  = seq [2]

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
    step r, s

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

  zeroes = BASE.toString()[1..]

  toString: ->
    parts = @digits?.reverse()?.dropWhile((d) -> d == 0)?.map (d) -> d.toString()
    if parts
      sign = if @sign < 0 then '-' else ''
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

# The `number` function provides the public interface.

number = (n = 0) ->
  switch typeof n
    when 'number'
      number.fromNative n
    when 'string'
      number.parse n
    else
      if n instanceof NumberBase
        n
      else
        throw new Error "expected a number, got #{n}"

number.fromNative = (n) ->
  throw new Error "expected an integer, got #{n}" unless n == Math.floor n
  asNum n

number.parse = (n) ->
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
# Exporting.

exports ?= this.pazy ?= {}
exports.number = number

# ----

# Some quick tests.

if quicktest
  show = (code) ->
    s = code.toString().replace /^function\s*\(\)\s*{\s*return\s*(.*);\s*}/, "$1"
    input = s + "                                    "[s.length..]

    output =
      try
        res = code()
        type = if res?.constructor?
          res.constructor.name
        else if res?
          typeof res
        if type? then "-> #{type} #{res}" else "-> #{res}"
      catch ex
        "!! #{ex}"

    log "#{input}#{output}"


  a = b = c = 0

  log ''
  show -> null
  show -> undefined

  log ''
  show -> number(98).gcd 21

  log ''
  show -> a = number Math.pow 2, 13
  show -> LongInt.fromNative a.val
  show -> a.plus 2
  show -> a.times 1
  show -> a.times 2
  show -> a.plus 2000

  log ''
  show -> number -123456789000000
  show -> number '-1234'
  show -> number '-123456789000000'

  log ''
  show -> number(123456789).plus  876543211
  show -> number(123456789).minus 123450000
  show -> number(123456789).minus 123456790
  show -> number(123456789).minus 123456789
  show -> number(123456789).plus -123450000

  log ''
  show -> number(12345).times 100001
