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
    sgn = LongInt.make(den).cmp(0)
    if sgn == 0
      throw new Error "denominator is zero"
    else if sgn < 0
      [n, d] = [LongInt.make(num).neg(), LongInt.make(den).neg()]
    else
      [n, d] = [LongInt.make(num), LongInt.make(den)]

    if quick
      @num__ = n
      @den__ = d
    else
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

  toString: ->
    if @den__.cmp(1) == 0
      @num__.toString()
    else
      "#{@num__.toString()}/#{@den__.toString()}"

  @operator: (names, arity, code) ->
    f = (args...) -> code.apply(this, convert x for x in args[...arity-1])
    @::[name] = f for name in names
    null

  @operator ['neg', '-'], 1, -> new Rational @num__.neg(), @den__, true

  @operator ['inv'], 1, -> new Rational @den__, @num__, true

  @operator ['abs'], 1, -> new Rational @num__.abs(), @den__, true

  @operator ['sign'], 1, -> @num__.sign()

  @operator ['plus', '+'], 2, (other) ->
    a = this.den__.gcd other.den__
    t = this.den__.div a
    n = other.den__.div(a).times(this.num__).plus t.times(other.num__)
    new Rational n, t.times other.den__

  @operator ['minus', '-'], 2, (other) -> this.plus other.neg()

  @operator ['cmp', '<=>'], 2, (other) -> this.minus(other).num__.cmp 0

  @operator ['times', '*'], 2, (other) ->
    a = this.num__.gcd other.den__
    b = this.den__.gcd other.num__
    n = this.num__.div(a).times other.num__.div(b)
    d = this.den__.div(b).times other.den__.div(a)
    new Rational n, d, true

  @operator ['div', '/'], 2, (other) -> this.times other.inv()

  @operator ['pow', '**'], 2, (other) ->
    throw new Error('exponent must be an integer') unless other.den__.cmp(1) == 0
    new Rational @num__.pow(other.num__), @den__.pow(other.num__)


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Rational = Rational
