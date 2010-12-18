# --------------------------------------------------------------------
# Arbitrary precision integers implemented in a functional style.
#
# !!! Very incomplete and very experimental !!!
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

# -- Importing

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require 'trampoline'
  { List }           = require 'list'
  { Stream }         = require 'stream'
else
  { recur, resolve, List, Stream } = this.pazy

# -- Call with '--test' for some quick-and-dirty testing

quicktest = process?.argv[0] == '--test'

# -- Setting the number base (maximal digit value - 1) and its square root

if quicktest
  [BASE, HALFBASE] = [10000, 100]
else
  [BASE, HALFBASE] = Stream.from(1)
    .map((n) -> [Math.pow(10, 2 * n), Math.pow(10, n)])
    .takeWhile(([b,h]) -> 2 * b - 2 != 2 * b - 1)
    .last()

# -- Useful constants

ZEROES = BASE.toString()[1..]
Z = new Stream 0

# -- Internal helper functions that operate on (streams of) digits/limbs

add = (r, s, c = 0) ->
  if c or (r and s)
    [r_, s_] = [r or Z, s or Z]
    x = r_.first() + s_.first() + c
    [digit, carry] = if x >= BASE then [x - BASE, 1] else [x, 0]
    new Stream(digit, -> add(r_.rest(), s_.rest(), carry))
  else
    s or r

sub = (r, s, b = 0) ->
  if b or (r and s)
    [r_, s_] = [r or Z, s or Z]
    x = r_.first() - s_.first() - b
    [digit, borrow] = if x < 0 then [x + BASE, 1] else [x, 0]
    new Stream(digit, -> sub(r_.rest(), s_.rest(), borrow))
  else
    s or r

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

streamTimesDigit = (s, d, c = 0) ->
  if c or s
    s_ = s or Z
    [lo, hi] = digitTimesDigit(d, s_.first())
    new Stream(lo + c, -> streamTimesDigit(s_.rest(), d, hi))

mul = (r, a, b) ->
  if a
    t = add(r, streamTimesDigit(b, a.first())) or Z
    new Stream(t.first(), -> mul(t.rest(), a.rest(), b))
  else
    r


# -- The glorious LongInt class

class LongInt
  constructor: (n = 0) ->
    make_digits = (m) ->
      if m then new Stream(m % BASE, -> make_digits(Math.floor m / BASE))

    [m, @sign] = if n < 0 then [-n, -1] else [n, 1]
    @digits = make_digits m

  base: -> BASE

  create = (digits, sign) ->
    n = new LongInt()
    n.digits = digits
    n.sign = sign
    n

  neg: -> create(@digits, -@sign)

  abs: -> create(@digits, 1)

  cmp: (other) ->
    step = (diff, r, s) ->
      if r and s
        recur -> step(new List(r.first() - s.first(), diff), r.rest(), s.rest())
      else if r or s
        if r then 1 else -1
      else
        diff.dropWhile((x) -> x == 0)?.first() or 0

    if this.sign != other.sign
      this.sign
    else
      this.sign * resolve step(null, this.digits, other.digits)

  plus: (other) ->
    if this.sign != other.sign
      this.minus other.neg()
    else
      create(add(this.digits, other.digits), this.sign)

  minus: (other) ->
    if this.sign != other.sign
      this.plus other.neg()
    else if this.abs().cmp(other.abs()) < 0
      create(sub(other.digits, this.digits), -this.sign)
    else
      create(sub(this.digits, other.digits), this.sign)

  times: (other) ->
    create mul(null, this.digits, other.digits), this.sign * other.sign

  toString: ->
    rev = @digits.reverse().dropWhile (d) -> d == 0
    buf = [rev?.first().toString()]
    rev?.rest()?.each (d) ->
      t = d.toString()
      buf.push "#{ZEROES[t.length..]}#{t}"
    if rev
      buf.unshift '-' if @sign < 0
    else
      buf.push '0'
    buf.join('')

  toNumber: ->
    step = (n, s) ->
      if s then recur -> step(n * BASE + s.first(), s.rest()) else n
    rev = @digits.reverse().dropWhile (d) -> d == 0
    @sign * resolve step(0, rev)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.LongInt = LongInt

if quicktest
  n = new LongInt(-99999999)
  console.log n.toString()
  console.log n.times(n).toString()
