# --------------------------------------------------------------------
# A sequence class vaguely inspired by Clojure's sequences.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require('trampoline')
else
  { recur, resolve } = this.pazy

class Sequence
  constructor: (src) ->
    if not src?
      @first = ->
      @rest  = -> null
    else if typeof src.sequence == 'function'
      seq = src.sequence()
      @first = -> seq.first()
      @rest  = -> seq.rest()
    else if typeof src.first == 'function' and typeof src.rest == 'function'
      @first = -> src.first()
      @rest  = -> src.rest()
    else if typeof src.length == 'number'
      n = src.length
      partial = (i) =>
        if i < n then Sequence.conj src[i], -> partial(i+1) else null
      @first = -> src[0]
      @rest  = -> partial(1)
    else
      throw new Error("cannot make a sequence from #{src}")

  @conj: (first, rest = (-> null), mode = null) ->
    r = rest() if mode == 'forced'
    new Sequence
      first: -> first
      rest:
        switch mode
          when 'stored' then -> val = rest(); (@rest = -> val)()
          when 'forced' then -> r
          else               -> rest()

  @from: (start) -> Sequence.conj start, => @from start+1

  @range: (start, end) -> @take__ @from(start), end - start + 1

  @::S = this

  make = (seq) ->
    if seq and (res = new Sequence(seq)) and typeof res.first() != 'undefined'
      res
    else
      null

  @memo: (name, f) ->
    @[name]        = (seq) -> f.call(this, make(seq))
    @["#{name}__"] = (seq) -> f.call(this, seq)
    @::[name]      =       -> x = f.call(@S, this); (@[name] = -> x)()

  @method: (name, f) ->
    @[name]        = (seq, args...) -> f.call(this, make(seq), args...)
    @["#{name}__"] = (seq, args...) -> f.call(this, seq, args...)
    @::[name]      = (args...)      -> f.call(@S, this, args...)

  @operator: (name, f) ->
    @[name]        = (seq, other, args...) -> f(make(seq), make(other), args...)
    @["#{name}__"] = (seq, other, args...) -> f.call(this, seq, other, args...)
    @::[name]      = (other, args...) -> f.call(@S, this, make(other), args...)

  @memo 'size', (seq) ->
    step = (s, n) -> if s then recur -> step s.rest(), n + 1 else n
    resolve step seq, 0

  @memo 'last', (seq) ->
    step = (s) -> if s.rest() then recur -> step s.rest() else s.first()
    resolve step seq

  @method 'take', (seq, n) ->
    if seq and n > 0
      Sequence.conj seq.first(), => @take__ seq.rest(), n-1
    else
      null

  @method 'takeWhile', (seq, pred) ->
    if seq and pred(seq.first())
      Sequence.conj seq.first(), => @takeWhile__ seq.rest(), pred
    else
      null

  @method 'drop', (seq, n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s.rest(), n - 1) else s
    resolve step seq, n

  @method 'dropWhile', (seq, pred) ->
    step = (s) -> if s and pred s.first() then recur -> step s.rest() else s
    resolve step seq

  @method 'get', (seq, n) => @drop__(seq, n)?.first() if n >= 0

  @method 'select', (seq, pred) ->
    if seq and pred seq.first()
      Sequence.conj seq.first(), => @select__ seq.rest(), pred
    else if seq and seq.rest()
      @select__ @dropWhile__(seq.rest(), (x) -> not pred x), pred
    else
      null

  @method 'find', (seq, pred) -> (@select__ seq, pred)?.first()

  @method 'forall', (seq, pred) -> not @select__ seq, (x) -> not pred x

  @method 'map', (seq, func) ->
    if seq
      Sequence.conj func(seq.first()), => @map__ seq.rest(), func
    else
      null

  @method 'accumulate', (seq, start, op) ->
    if seq
      first = op start, seq.first()
      Sequence.conj first, => @accumulate__ seq.rest(), first, op
    else
      null

  @method 'sums',     (seq) -> @accumulate__ seq, 0, (a,b) -> a + b
  @method 'products', (seq) -> @accumulate__ seq, 1, (a,b) -> a * b

  @method 'reduce', (seq, start, op) -> @accumulate__(seq, start, op).last()

  @method 'sum',     (seq) -> @reduce__ seq, 0, (a,b) -> a + b
  @method 'product', (seq) -> @reduce__ seq, 1, (a,b) -> a * b

  @operator 'combine', (seq, other, op) ->
    if seq and other
      Sequence.conj op(seq.first(), other.first()), =>
        if seq.rest() and other.rest()
          @combine__ seq.rest(), other.rest(), op
    else
      null

  @operator 'plus',  (seq, other) -> @combine__ seq, other, (a,b) -> a + b
  @operator 'minus', (seq, other) -> @combine__ seq, other, (a,b) -> a - b
  @operator 'times', (seq, other) -> @combine__ seq, other, (a,b) -> a * b
  @operator 'div',   (seq, other) -> @combine__ seq, other, (a,b) -> a / b

  @operator 'equals', (seq, other) ->
    @combine__(seq, other, (a,b) -> a == b).reduce true, (a,b) -> a && b

  @operator 'interleave', (seq, other) ->
    if seq
      Sequence.conj seq.first(), => @interleave__ other, seq.rest()
    else
      other

  lazyConcat = (seq, next) ->
    if seq
      Sequence.conj seq.first(), -> lazyConcat seq.rest(), next
    else
      next()

  @operator 'concat', (seq, other) -> lazyConcat seq, -> other

  @method 'flatten', (seq) ->
    if seq and seq.first()
      lazyConcat make(seq.first()), => @flatten__ seq.rest()
    else if seq and seq.rest()
      @flatten__ @dropWhile__ seq.rest(), (x) -> not x.first()
    else
      null

  @method 'flatMap', (seq, func) -> @flatten__ @map__ seq, func

  @operator 'cartesian', (seq, other) ->
    @flatMap__ seq, (a) => @map__ other, (b) -> [a,b]

  @method 'each', (seq, func) ->
    step = (s) -> if s then func(s.first()); recur -> step s.rest()
    resolve step seq

  @method 'reverse', (seq) ->
    step = (r, s) =>
      if s then recur => step Sequence.conj(s.first(), -> r), s.rest() else r
    resolve step null, seq

  @method 'stored', (seq) ->
    if seq
      Sequence.conj seq.first(), (=> @stored__ seq.rest()), 'stored'
    else
      null

  @method 'forced', (seq) ->
    if seq
      Sequence.conj seq.first(), (=> @forced__ seq.rest()), 'forced'
    else
      null

  @method 'into', (seq, target) ->
    if not target?
      @reduce__ seq, null, (s, item) -> Sequence.conj item, -> s
    else if typeof target.plus == 'function'
      @reduce__ seq, target, (s, item) -> s.plus item
    else if typeof target.length == 'number'
      a = (x for x in target)
      @each__ seq, (x) -> a.push x
      a
    else
      throw new Error('cannot inject into #{target}')

  toString: (limit = 10) ->
    [s, more] = if limit > 0
      [@take(limit), @get(limit)?]
    else
      [this, false]
    '(' + s.into([]).join(', ') + if more then ', ...)' else ')'


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sequence = Sequence
