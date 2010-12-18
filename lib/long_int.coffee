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

  dump = (s) -> "[#{if s then s.toArray() else ''}]"
  log = (str) -> console.log str
else
  dump = (s) ->
  log = (str) ->

  [BASE, HALFBASE] = Stream.from(1)
    .map((n) -> [Math.pow(10, 2 * n), Math.pow(10, n)])
    .takeWhile(([b,h]) -> 2 * b - 2 != 2 * b - 1)
    .last()

# -- Useful constants

ZERO = new Stream 0
ONE = new Stream 1

# -- Internal helper functions that operate on (streams of) digits/limbs

cleanup = (s) -> s?.reverse()?.dropWhile((x) -> x == 0)?.reverse() or null

cmp = (r, s) ->
  step = (diff, r, s) ->
    if r and s
      recur -> step(new List(r.first() - s.first(), diff), r.rest(), s.rest())
    else if r or s
      if r then 1 else -1
    else
      diff.dropWhile((x) -> x == 0)?.first() or 0
  resolve step null, r, s

add = (r, s, c = 0) ->
  if c or (r and s)
    [r_, s_] = [r or ZERO, s or ZERO]
    x = r_.first() + s_.first() + c
    [digit, carry] = if x >= BASE then [x - BASE, 1] else [x, 0]
    new Stream(digit, -> add(r_.rest(), s_.rest(), carry))
  else
    s or r

sub = (r, s) ->
  step = (r, s, b = 0) ->
    if b or (r and s)
      [r_, s_] = [r or ZERO, s or ZERO]
      x = r_.first() - s_.first() - b
      [digit, borrow] = if x < 0 then [x + BASE, 1] else [x, 0]
      new Stream(digit, -> step(r_.rest(), s_.rest(), borrow))
    else
      s or r
  cleanup step(r, s)

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
    s_ = s or ZERO
    [lo, hi] = digitTimesDigit(d, s_.first())
    new Stream(lo + c, -> streamTimesDigit(s_.rest(), d, hi))

mul = (r, a, b) ->
  if a
    t = add(r, streamTimesDigit(b, a.first())) or ZERO
    new Stream(t.first(), -> mul(t.rest(), a.rest(), b))
  else
    r

divmod = (r, s) ->
  step = (q, h, t, shift) ->
    n = (h?.last() * if shift then BASE else 1) or 0
    d = s.last() + 1
    f = (Math.floor n / d) or (if cmp(h, s) >= 0 then 1 else 0)
    log "divmod step(#{dump(q)}, #{dump(h)}, #{dump(t)}, #{shift}) -- f = #{f}"
    [q_, h_] = [add(q, new Stream(f)), sub(h, streamTimesDigit(s, f))]

    if f and not shift
      recur -> step(q_, h_, t, shift)
    else if shift
      recur -> step(q_, h_, t, false)
    else if t
      recur -> step(
        new Stream(0, -> q_),
        new Stream(t.first(), -> h_),
        t.rest(),
        h_.last() != 0)
    else
      log "  returning [#{dump(q_)},#{dump(h_)}]"
      [q_, h_]

  m = r.size() - s.size()
  resolve step(null, r.drop(m), r.take(m)?.reverse(), false)


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
    if this.sign != other.sign
      this.sign
    else
      this.sign * cmp(this.digits, other.digits)

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

  div: (other) ->
    d = this.abs().cmp other.abs()
    if d < 0
      new LongInt(0)
    else if d == 0
      new LongInt(this.sign * other.sign)
    else
      create(divmod(this.digits, other.digits)[0], this.sign * other.sign)

  mod: (other) ->
    d = this.abs().cmp other.abs()
    if d < 0
      this
    else if d == 0
      ZERO
    else
      create(divmod(this.digits, other.digits)[1], this.sign)

  toString: ->
    zeroes = BASE.toString()[1..]

    rev = @digits?.reverse()?.dropWhile (d) -> d == 0
    buf = [rev?.first().toString()]
    rev?.rest()?.each (d) ->
      t = d.toString()
      buf.push "#{zeroes[t.length..]}#{t}"
    if rev
      buf.unshift '-' if @sign < 0
    else
      buf.push '0'
    buf.join('')

  toNumber: ->
    step = (n, s) ->
      if s then recur -> step(n * BASE + s.first(), s.rest()) else n
    rev = @digits?.reverse()?.dropWhile (d) -> d == 0
    @sign * resolve step(0, rev)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.LongInt = LongInt

if quicktest
  one = new LongInt 1
  a = new LongInt 9950
  a2 = a.times a
  a3 = a2.times a
  a3inc = a3.plus(one)
  a3dec = a3.minus(one)
  log "(#{a}**3 + 1) / #{a}**2 = #{a3inc.div(a2)} (#{a3inc.mod(a2)})"
  log ""
  log "(#{a}**3 - 1) / #{a}**2 = #{a3dec.div(a2)} (#{a3dec.mod(a2)})"
  log ""

  b = new LongInt 111111111
  c = new LongInt 37
  log "#{b} / #{c} = #{b.div c} (#{b.mod c})"
  log ""
