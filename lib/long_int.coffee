# --------------------------------------------------------------------
# Arbitrary precision integers implemented in a functional style.
#
# !!! Very incomplete and very experimental !!!
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

# -- Importing

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { trampoline } = require 'functional'
  { seq }  = require 'sequence'
else
  { trampoline, seq } = this.pazy

# -- Call with '--test' for some quick-and-dirty testing

quicktest = module? and not module.parent

# -- Setting the number base (maximal digit value - 1) and its square root

rdump = (s) -> "#{if s then s.into([]).join('|') else '[]'}"
dump = (s) -> rdump s?.reverse()

if quicktest
  [BASE, HALFBASE] = [10000, 100]
  log = (str) -> console.log str
else
  log = (str) ->

  [BASE, HALFBASE] = seq.from(1)
    .map((n) -> [Math.pow(10, 2 * n), Math.pow(10, n)])
    .takeWhile(([b,h]) -> 2 * b - 2 != 2 * b - 1)
    .last()

# -- Useful constants

ZERO = seq.conj 0
ONE  = seq.conj 1
TWO  = seq.conj 2

# -- Internal helper functions that operate on (sequences of) digits/limbs

cleanup = (s) -> s?.reverse()?.dropWhile((x) -> x == 0)?.reverse() or null

cmp = (r, s) -> seq.sub(r, s)?.reverse()?.dropWhile((x) -> x == 0)?.first() or 0

add = (r, s, c = 0) ->
  if c or (r and s)
    [r_, s_] = [r or ZERO, s or ZERO]
    x = r_.first() + s_.first() + c
    [digit, carry] = if x >= BASE then [x - BASE, 1] else [x, 0]
    seq.conj(digit, -> add(r_.rest(), s_.rest(), carry))
  else
    s or r

sub = (r, s) ->
  step = (r, s, b = 0) ->
    if b or (r and s)
      [r_, s_] = [r or ZERO, s or ZERO]
      x = r_.first() - s_.first() - b
      [digit, borrow] = if x < 0 then [x + BASE, 1] else [x, 0]
      seq.conj(digit, -> step(r_.rest(), s_.rest(), borrow))
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

divmod = (r, s) ->
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
      [cleanup(q), h && div(h, seq.conj(scale))]

  trampoline step(null, null, r_.reverse())

div = (r, s) -> divmod(r, s)[0]

mod = (r, s) -> divmod(r, s)[1]

pow = (r, s) ->
  step = (p, r, s) ->
    if s
      if s.first() % 2 == 1
        -> step(mul(p, r), r, sub(s, ONE))
      else
        -> step(p, seq(mul(r, r)), div(s, TWO))
    else
      p
  trampoline step(ONE, r, s)

sqrt = (s) ->
  n = s.size()
  if n == 1
    seq.conj Math.floor Math.sqrt s.first()
  else
    step = (r) ->
      rn = seq div(add(r, div(s, r)), TWO)
      if cmp(r, rn) then -> step(rn) else rn
    trampoline step s.take n >> 1


# -- The glorious LongInt class

class LongInt
  @base: -> BASE

  constructor: (n = 0) ->
    make_digits = (m) ->
      if m then seq.conj(m % BASE, -> make_digits(Math.floor m / BASE))

    [m, @sign__] = if n < 0 then [-n, -1] else [n, 1]
    @digits__ = cleanup seq make_digits m

  create = (digits, sign) ->
    n = new LongInt()
    n.digits__ = cleanup seq digits
    n.sign__   = if n.digits__? then sign else 1
    n

  @make: (x) ->
    if x instanceof LongInt
      x
    else if x instanceof CheckedInt
      new LongInt x.val
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
      if s then -> step(n * BASE + s.first(), s.rest()) else n
    rev = @digits__?.reverse()?.dropWhile (d) -> d == 0
    @sign() * trampoline step(0, rev)

  @operator: (names, arity, code) ->
    f = (args...) -> code.apply(this, LongInt.make x for x in args[...arity-1])
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
    d = this.abs().cmp other.abs()
    if d < 0
      this
    else if d == 0
      new LongInt(0)
    else
      create(mod(this.digits__, other.digits__), this.sign() * other.sign())

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

  @operator ['gcd'], 2, (other) ->
    step = (a, b) -> if b.cmp(0) > 0 then -> step b, a.mod b else a
    [a, b] = [this.abs(), other.abs()]
    if a.cmp(b) > 0 then trampoline step a, b else trampoline step b, a


# -- The CheckedInt class provides integer operations that propagate
#    to LongInt on overflow.

class CheckedInt
  constructor: (val = 0) ->
    if typeof val != "number"
      throw new Error "#{val} is not a number"
    else if val % 1
      throw new Error "#{val} is not an integer"
    else if Math.abs(val) >= BASE
      throw new Error "#{val} is not between #{-BASE+1} and #{BASE-1}"
    else
      @val = val

  @make: (x) ->
    if x instanceof CheckedInt
      x
    else
      new CheckedInt x

  make = (val) ->
    if Math.abs(val) < BASE then new CheckedInt val else new LongInt val

  @operator: (names, arity, code) ->
    f = (args...) -> code.apply(this,
                                CheckedInt.make x for x in args[...arity-1])
    @::[name] = f for name in names
    null

  @operator ['neg', '-'], 1, -> new CheckedInt -@val

  @operator ['abs'], 1, -> new CheckedInt Math.abs @val

  @operator ['cmp', '<=>'], 2, (other) ->
    if @val < other.val then -1 else if @val > other.val then 1 else 0

  @operator ['sgn'], 1, -> @cmp 0

  @operator ['plus', '+'], 2, (other) -> make @val + other.val

  @operator ['minus', '-'], 2, (other) -> make @val - other.val

  @operator ['times', '*'], 2, (other) ->
    tmp = @val * other.val
    if Math.abs(tmp) < BASE
      new CheckedInt tmp
    else
      new LongInt(@val).times other.val

  @operator ['div', '/'], 2, (other) -> make (@val / other.val) >> 0

  @operator ['mod', '%'], 2, (other) -> make @val % other.val

  @operator ['pow', '**'], 2, (other) ->
    switch other.sgn()
      when  0 then 1
      when -1 then throw Error 'exponent must not be negative'
      else
        tmp = Math.pow @val, other.val
        if Math.abs(tmp) < BASE
          new CheckedInt tmp
        else
          new LongInt(@val).pow other.val

  @operator ['sqrt'], 1, -> Math.sqrt(@val) >> 0

  @operator ['gcd'], 2, (other) ->
    step = (a, b) -> if b > 0 then -> step b, a % b else a
    [a, b] = [Math.abs(@val), Math.abs(other.val)]
    val = if a > b then trampoline step a, b else trampoline step b, a
    new CheckedInt val

  toString: -> "" + @val


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.LongInt = LongInt

if quicktest
  a = new CheckedInt 9950
  log "a = #{a}"
  a2 = a['*'] a
  log "a * a = #{a2}"
  a3 = a2['*'] a
  log "(#{a}**3 + 1) / #{a}**2 = #{a3.plus(1).div a2} (#{a3.plus(1).mod a2})"
  log ""
  log "(#{a}**3 - 1) / #{a}**2 = #{a3.minus(1).div a2} (#{a3.minus(1).mod a2})"
  log ""

  b = new LongInt 111111112
  log "#{b} / 37 = #{b.div 37} (#{b.mod 37})"
  log ""

  c = new LongInt (2 << 26) * 29 * 31
  d = new LongInt 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29 * 31
  log "#{c} gcd #{d} = #{c.gcd d} (expected #{29 * 31})"
  log ""

  e = new CheckedInt(5).pow 5
  log "5**5 = #{e}"
  log "class of 5**5 is #{e.constructor.name}"
  f = new CheckedInt(5).pow 6
  log "5**6 = #{f}"
  log "class of 5**6 is #{f.constructor.name}"
