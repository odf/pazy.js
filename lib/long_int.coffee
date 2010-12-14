# --------------------------------------------------------------------
# Arbitrary precision integers implemented in a functional style.
#
# !!! Very incomplete and very experimental !!!
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Stream } = require 'stream'
else
  { Stream } = this.pazy


class LongInt
  BLEN = 3
  BASE = eval "1e#{BLEN}"
  ZEROES = ('0' for i in [1..BLEN]).join ''
  Z = new Stream(0)

  constructor: (@digits, @sign = 1) ->

  neg: -> new LongInt(@digits, -@sign)

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
      new LongInt(add(this.digits, other.digits), this.sign)

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
    else
      digits = sub(this.digits, other.digits)
      if digits.last() < 0
        new LongInt(sub(other.digits, this.digits), -this.sign)
      else
        new LongInt(digits, this.sign)

  toString: (sep = '') ->
    rev = @digits.reverse().drop_while (d) -> d == 0
    buf = [rev?.first().toString()]
    rev?.rest()?.each (d) ->
      t = d.toString()
      buf.push "#{sep}#{ZEROES[t.length..]}#{t}"
    if rev
      buf.unshift '-' if @sign < 0
    else
      buf.push '0'
    buf.join('')


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.LongInt = LongInt

## Test code

a = new LongInt(Stream.fromArray([499, 999, 999, 999]), -1)
b = new LongInt(Stream.fromArray [501])

console.log "a   = #{a.toString('_')}"
console.log "b   = #{b.toString('_')}"
console.log "a+b = #{(a.plus b).toString('_')}"
console.log "a-b = #{(a.minus b).toString('_')}"
console.log "a-a = #{(a.minus a).toString('_')}"
console.log "b-a = #{(b.minus a).toString('_')}"

###
