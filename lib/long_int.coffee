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

rdump = (s) -> "#{if s then s.toArray().join('|') else '[]'}"
dump = (s) -> rdump s?.reverse()

if quicktest
  [BASE, HALFBASE] = [10000, 100]
  log = (str) -> console.log str
else
  log = (str) ->

  [BASE, HALFBASE] = Stream.from(1)
    .map((n) -> [Math.pow(10, 2 * n), Math.pow(10, n)])
    .takeWhile(([b,h]) -> 2 * b - 2 != 2 * b - 1)
    .last()

# -- Useful constants

ZERO = new Stream 0
ONE  = new Stream 1
TWO  = new Stream 2

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

mul = (a, b) ->
  step = (r, a, b) ->
    if a
      t = add(r, streamTimesDigit(b, a.first())) or ZERO
      new Stream(t.first(), -> step(t.rest(), a.rest(), b))
    else
      r
  step null, a, b

div = (r, s) ->
  f = Math.floor BASE / (s.last() + 1)
  [r_, s_] = (streamTimesDigit(x, f) for x in [r, s])
  log "div(#{dump r}, #{dump s}): premultiplying by #{f}, divisor ~> #{dump s_}"
  [m, d] = [s_.size(), s_.last() + 1]

  step = (q, h, t) ->
    n = (h?.last() * if h?.size() > m then BASE else 1) or 0
    f = (Math.floor n / d) or (if cmp(h, s_) >= 0 then 1 else 0)
    log "  step(#{dump q}, #{dump h}, #{rdump t}) -- f = #{f}"

    if f
      recur -> step(add(q, new Stream(f)), sub(h, streamTimesDigit(s_, f)), t)
    else if t
      recur -> step(new Stream(0, -> q), new Stream(t.first(), -> h), t.rest())
    else
      log "  returning #{dump cleanup q}"
      cleanup q

  resolve step(null, null, r_.reverse())

pow = (r, s) ->
  step = (p, r, s) ->
    if s
      if s.first() % 2 == 1
        recur -> step(mul(p, r), r, sub(s, ONE))
      else
        recur -> step(p, mul(r, r), div(s, TWO))
    else
      p
  resolve step(ONE, r, s)

sqrt = (s) ->
  n = s.size()
  if n == 1
    new Stream Math.floor Math.sqrt s.first()
  else
    step = (r) ->
      rn = div(add(r, div(s, r)), TWO)
      if cmp(r, rn) then recur -> step(rn) else rn
    resolve step s.take n >> 1


# -- The glorious LongInt class

class LongInt
  @base: -> BASE

  constructor: (n = 0) ->
    make_digits = (m) ->
      if m then new Stream(m % BASE, -> make_digits(Math.floor m / BASE))

    [m, @sign__] = if n < 0 then [-n, -1] else [n, 1]
    @digits__ = make_digits m

  create = (digits, sign) ->
    n = new LongInt()
    n.digits__ = digits
    n.sign__ = sign
    n

  convert = (x) ->
    if x instanceof @constructor
      x
    else if typeof x == 'number'
      new LongInt x
    else
      throw new Error("#{x} is not a number")

  toString: ->
    zeroes = BASE.toString()[1..]

    rev = @digits__?.reverse()?.dropWhile (d) -> d == 0
    buf = [rev?.first().toString()]
    rev?.rest()?.each (d) ->
      t = d.toString()
      buf.push "#{zeroes[t.length..]}#{t}"
    if rev
      buf.unshift '-' if @sign() < 0
    else
      buf.push '0'
    buf.join('')

  toNumber: ->
    step = (n, s) ->
      if s then recur -> step(n * BASE + s.first(), s.rest()) else n
    rev = @digits__?.reverse()?.dropWhile (d) -> d == 0
    @sign() * resolve step(0, rev)

  @operator: (names, arity, code) ->
    f = (args...) -> code.apply(this, convert x for x in args[...arity-1])
    @::[name] = f for name in names
    null

  @operator ['neg', '-'], 1, -> create(@digits__, -@sign())

  @operator ['abs'], 1, -> create(@digits__, 1)

  @operator ['sign'], 1, -> @sign__

  @operator ['cmp', '<=>'], 2, (other) ->
    if this.sign() != other.sign()
      this.sign()
    else
      this.sign() * cmp(this.digits__, other.digits__)

  @operator ['plus', '+'], 2, (other) ->
    if this.sign() != other.sign()
      this.minus other.neg()
    else
      create(add(this.digits__, other.digits__), this.sign())

  @operator ['minus', '-'], 2, (other) ->
    if this.sign() != other.sign()
      this.plus other.neg()
    else if this.abs().cmp(other.abs()) < 0
      create(sub(other.digits__, this.digits__), -this.sign())
    else
      create(sub(this.digits__, other.digits__), this.sign())

  @operator ['times', '*'], 2, (other) ->
    create mul(this.digits__, other.digits__), this.sign() * other.sign()

  @operator ['div', '/'], 2, (other) ->
    d = this.abs().cmp other.abs()
    if d < 0
      new LongInt(0)
    else if d == 0
      new LongInt(this.sign() * other.sign())
    else
      create(div(this.digits__, other.digits__), this.sign() * other.sign())

  @operator ['mod', '%'], 2, (other) ->
    this.minus(this.div(other).times(other))

  @operator ['pow', '**'], 2, (other) ->
    if other.sign() > 0
      create(pow(this.digits__, other.digits__), this.sign())
    else
      throw new Error('exponent must not be negative')

  @operator ['sqrt'], 1, ->
    if @sign() > 0
      create sqrt this.digits__
    else
      throw new Error('number must not be negative')


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.LongInt = LongInt

if quicktest
  a = new LongInt 9950
  a2 = a['*'] a
  a3 = a2['*'] a
  log "(#{a}**3 + 1) / #{a}**2 = #{a3.plus(1).div a2} (#{a3.plus(1).mod a2})"
  log ""
  log "(#{a}**3 - 1) / #{a}**2 = #{a3.minus(1).div a2} (#{a3.minus(1).mod a2})"
  log ""

  b = new LongInt 111111112
  log "#{b} / 37 = #{b.div 37} (#{b.mod 37})"
  log ""
