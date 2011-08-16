# A general number class, currently supporting integral Javascript numbers,
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

# If this source file was executed directly, some simple tests are performed.

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
# `HALFBASE` it its square root.

[BASE, HALFBASE] = if quicktest then [10000, 100] else
  seq.from(1)
    .map((n) -> [Math.pow(10, 2 * n), Math.pow(10, n)])
    .takeWhile(([b,h]) -> 2 * b - 2 != 2 * b - 1 and -2 * b + 2 != -2 * b + 1)
    .last()

# ----

# The `CheckInt` class provides integer operations with 'overflow checks'. In
# other words, if the result cannot be represented with full precision as a
# Javascript number, a `LongInt` is produced instead.

class CheckedInt
  getval = (x) -> if x instanceof CheckedInt then x.val else x

  yield  = (x) -> if Math.abs(x) < BASE then new CheckedInt x else new LongInt x

  constructor: (@val = 0) ->

  neg: -> new CheckedInt -@val

  abs: -> new CheckedInt Math.abs @val

  sgn: -> if @val < 0 then -1 else if @val > 0 then 1 else 0

  sqrt: -> new CheckedInt Math.sqrt(@val) >> 0

  cmp: (other) ->
    x = getval other
    if @val < x then -1 else if @val > x then 1 else 0

  plus: (other) -> yield @val + getval other

  minus: (other) -> yield @val - getval other

  times: (other) ->
    tmp = @val * getval other
    if Math.abs(tmp) < BASE
      new CheckedInt tmp
    else
      new LongInt(@val).times other

  div: (other) -> new CheckedInt (@val / getval other) >> 0

  mod: (other) -> new CheckedInt @val % getval other

  gcd: (other) ->
    step = (a, b) -> if b > 0 then -> step b, a % b else a

    [a, b] = [Math.abs(@val), Math.abs(getval other)]
    new CheckedInt if a > b then trampoline step a, b else trampoline step b, a

  toString: -> "" + @val

# ----

# Here are the beginnings of the `LongInt` class.

class LongInt
  make_digits = (m) ->
    if m then seq.conj m % BASE, -> make_digits (m / BASE) >> 0 else null

  constructur: (n = 0) ->
    [m, @sign] = if n < 0 then [-n, -1] else [n, 1]
    @digits = make_digits m

  times: (other) ->

  zeroes = BASE.toString()[1..]

  toString: ->
    parts = @digits?.reverse()?.dropWhile((d) -> d == 0)?.map (d) -> d.toString()
    if parts
      sign = if @sign < 0 then '-' else ''
      rest = parts.rest()?.map (t) -> "#{zeroes[t.length..]}#{t}"
      sign + parts.first() + rest.join ''
    else
      '0'

# ----

# Some quick tests.

if quicktest
  do ->
    log "------"
    a = 98
    b = 21
    log "gcd(#{a}, #{b}) = #{new CheckedInt(a).gcd b}"

  do ->
    log "------"
    a = new CheckedInt Math.pow 2, 13
    log "a        = #{a}"
    log "a * 2    = #{a.times 2}"
    log "a + 2    = #{a.plus 2}"
    log "a + 2000 = #{a.plus 2000}"

  do ->
    log "------"
    a = -123456789000000
    log "a = #{a}"
