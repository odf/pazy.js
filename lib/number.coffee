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

digits = (m) ->
  if m then seq.conj m % BASE, -> digits Math.floor(m / BASE) else null

# ----

# The `CheckInt` class provides integer operations with 'overflow checks'. In
# other words, if the result cannot be represented with full precision as a
# Javascript number, a `LongInt` is produced instead.

class CheckedInt
  getval = (x) -> if x instanceof CheckedInt then x.val else x

  constructor: (@val = 0) ->

  neg: -> new CheckedInt -@val

  abs: -> new CheckedInt Math.abs @val

  sgn: -> if @val < 0 then -1 else if @val > 0 then 1 else 0

  sqrt: -> new CheckedInt Math.floor Math.sqrt @val

  cmp: (other) ->
    x = getval other
    if @val < x then -1 else if @val > x then 1 else 0

  plus: (other) -> asNum @val + getval other

  minus: (other) -> asNum @val - getval other

  times: (other) ->
    x = @val * getval other
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

class LongInt
  constructor: (@sign = 0, @digits = null) ->

  times: (other) -> throw new Error "not yet implemented"

  zeroes = BASE.toString()[1..]

  toString: ->
    parts = @digits?.reverse()?.dropWhile((d) -> d == 0)?.map (d) -> d.toString()
    if parts
      sign = if @sign < 0 then '-' else ''
      rest = parts.rest()?.map (t) -> "#{zeroes[t.length..]}#{t}"
      sign + parts.first() + rest.join ''
    else
      '0'

  @fromNative: (n) ->
    if n < 0
      new LongInt -1, digits -n
    else if n > 0
      new LongInt 1, digits n
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
  blanks = "                                    "

  show = (code) ->
    s = code.toString().replace /^function\s*\(\)\s*{\s*return\s+(.*);\s*}/, "$1"
    input = s + blanks[s.length..]

    output =
      try
        res = code()
        type = if res?.constructor? then res.constructor.name else typeof res
        "#{type} #{res}"
      catch ex
        "-- #{ex} --"

    log "#{input} -> #{output}"


  a = b = c = 0

  log ''
  show -> number(98).gcd 21

  log ''
  show -> a = number Math.pow 2, 13
  show -> a.plus 2
  show -> a.times 2
  show -> a.plus 2000

  log ''
  show -> number -123456789000000
  show -> number '-1234'
  show -> number '-123456789000000'
