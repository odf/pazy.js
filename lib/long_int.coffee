# --------------------------------------------------------------------
# Arbitrary precision integers implemented in a functional style.
#
# !!! Very incomplete and very experimental !!!
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require 'trampoline'
  { List }           = require 'list'
  { Stream }         = require 'stream'
else
  { recur, resolve, List, Stream } = this.pazy


BASE = ZEROES = undefined
Z = new Stream 0

set_digit_size = (n) ->
  BASE = Math.pow 10, n
  ZEROES = ('0' for i in [1..n]).join ''

even = (n) -> n % 2 == 0
good = (n) -> b = Math.pow 10, n; 2 * b - 2 != 2 * b - 1
set_digit_size Stream.from(1).select(even).take_while(good).last()


class LongInt
  @digit_size__ = (n) -> set_digit_size(n)

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
    cmp = (diff, r, s) ->
      if r and s
        recur -> cmp(new List(r.first() - s.first(), diff), r.rest(), s.rest())
      else if r or s
        if r then 1 else -1
      else
        diff.drop_while((x) -> x == 0)?.first() or 0

    if this.sign != other.sign
      this.sign
    else
      this.sign * resolve cmp(null, this.digits, other.digits)

  plus: (other) ->
    add = (r, s, c = 0) ->
      if c or (r and s)
        [r_, s_] = [r or Z, s or Z]
        x = r_.first() + s_.first() + c
        [digit, carry] = if x >= BASE then [x - BASE, 1] else [x, 0]
        new Stream(digit, -> add(r_.rest(), s_.rest(), carry))
      else
        s or r

    if this.sign != other.sign
      this.minus other.neg()
    else
      create(add(this.digits, other.digits), this.sign)

  minus: (other) ->
    sub = (r, s, b = 0) ->
      if b or (r and s)
        [r_, s_] = [r or Z, s or Z]
        x = r_.first() - s_.first() - b
        [digit, borrow] = if x < 0 then [x + BASE, 1] else [x, 0]
        new Stream(digit, -> sub(r_.rest(), s_.rest(), borrow))
      else
        s or r

    if this.sign != other.sign
      this.plus other.neg()
    else if this.abs().cmp(other.abs()) < 0
      create(sub(other.digits, this.digits), -this.sign)
    else
      create(sub(this.digits, other.digits), this.sign)

  toString: ->
    rev = @digits.reverse().drop_while (d) -> d == 0
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
    rev = @digits.reverse().drop_while (d) -> d == 0
    @sign * resolve step(0, rev)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.LongInt = LongInt
