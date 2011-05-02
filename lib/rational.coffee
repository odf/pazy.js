# --------------------------------------------------------------------
# Rational numbers.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { LongInt } = require 'long_int'
else
  { LongInt } = this.pazy


class Rational
  constructor: (num = 0, den = 1, quick = false) ->
    if quick
      @num__ = num
      @den__ = den
    else
      sgn = LongInt.make(den).cmp(0)
      if sgn == 0
        throw new Error "denominator is zero"
      else if sgn < 0
        [n, d] = [LongInt.make(num).neg(), LongInt.make(den).neg()]
      else
        [n, d] = [LongInt.make(num), LongInt.make(den)]

      a = n.gcd d
      @num__ = n.div a
      @den__ = d.div a

  @numerator: -> @num__
  @denominator: -> @den__

  convert = (x) ->
    if x instanceof Rational
      x
    else if x instanceof LongInt
      new Rational x
    else if typeof x == 'number'
      new Rational x
    else
      throw new Error "#{x} is not a number"

  toString: -> "#{@num__.toString()}/#{@den__.toString()}"

  @operator: (names, arity, code) ->
    f = (args...) -> code.apply(this, convert x for x in args[...arity-1])
    @::[name] = f for name in names
    null

  @operator ['neg', '-'], 1, -> new Rational(@num__.neg(), @den__, true)

  @operator ['abs'], 1, -> new Rational(@num__.abs(), @den__, true)

  @operator ['sign'], 1, -> @num__.sign()

  @operator ['plus', '+'], 2, (other) ->
    a = this.den__.gcd other.den__
    t = this.den__.div a
    n = other.den__.div(a).times(this.num__).plus t.times(other.num__)
    new Rational n, t.times(other.den__)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Rational = Rational
