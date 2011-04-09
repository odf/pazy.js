# --------------------------------------------------------------------
# A sequence class vaguely inspired by Clojure's sequences.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

#TODO catch missing return values from function arguments

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require('functional')
else
  { recur, resolve } = this.pazy

class Sequence
  constructor: (src) ->
    if not src?
      @first = ->
      @rest  = -> null
    else if typeof src.toSeq == 'function'
      seq = src.toSeq()
      if seq?
        @first = -> seq.first()
        @rest  = -> seq.rest()
      else
        @first = ->
        @rest  = -> null
    else if typeof src.first == 'function' and typeof src.rest == 'function'
      @first = -> src.first()
      @rest  = -> src.rest()
    else if typeof src.length == 'number'
      n = src.length
      partial = (i) ->
        i += 1 while i < n and typeof(src[i]) == 'undefined'
        if i < n then Sequence.conj src[i], -> partial(i+1) else null
      dummy = partial(0)
      if dummy
        @first = -> dummy.first()
        @rest  = -> dummy.rest()
      else
        @first = ->
        @rest  = -> null
    else
      throw new Error("cannot make a sequence from #{src}")

  @accepts: (src) ->
    not src? or
    typeof(src.toSeq) == 'function' or
    (typeof(src.first) == 'function' and typeof(src.rest) == 'function') or
    typeof(src.length) == 'number'

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

  make = (seq) ->
    if seq and (res = new Sequence(seq)) and not res.empty() then res else null

  @::S__ = this

  @memo: (name, f) ->
    @[name]        = (seq) -> f.call(this, make(seq))
    @["#{name}__"] = (seq) -> f.call(this, seq)
    @::[name]      =       -> x = f.call(@S__, this); (@[name] = -> x)()

  @method: (name, f) ->
    @[name]        = (seq, args...) -> f.call(this, make(seq), args...)
    @["#{name}__"] = (seq, args...) -> f.call(this, seq, args...)
    @::[name]      = (args...)      -> f.call(@S__, this, args...)

  @operator: (name, f) ->
    @[name]        = (seq, other, args...) ->
                       f.call(this, make(seq), make(other), args...)
    @["#{name}__"] = (seq, other, args...) -> f.call(this, seq, other, args...)
    @::[name]      = (other, args...) -> f.call(@S__, this, make(other), args...)

  @method 'empty', (seq) ->
    not seq? or typeof(seq.first()) == 'undefined'

  @memo 'size', (seq) ->
    step = (s, n) -> if s then recur -> step s.rest(), n + 1 else n
    if @empty__ seq then 0 else resolve step seq, 0

  @memo 'last', (seq) ->
    step = (s) -> if s.rest() then recur -> step s.rest() else s.first()
    resolve step seq unless @empty__ seq

  @method 'take', (seq, n) ->
    if @empty__(seq) or n <= 0
      null
    else
      Sequence.conj seq.first(), => @take__ seq.rest(), n-1

  @method 'takeWhile', (seq, pred) ->
    if @empty__(seq) or not pred(seq.first())
      null
    else
      Sequence.conj seq.first(), => @takeWhile__ seq.rest(), pred

  @method 'drop', (seq, n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s.rest(), n - 1) else s
    if @empty__(seq) then null else resolve step seq, n

  @method 'dropWhile', (seq, pred) ->
    step = (s) -> if s and pred s.first() then recur -> step s.rest() else s
    if @empty__(seq) then null else resolve step seq

  @method 'get', (seq, n) => @drop__(seq, n)?.first() if n >= 0

  @method 'select', (seq, pred) ->
    if @empty__ seq
      null
    else if pred seq.first()
      Sequence.conj seq.first(), => @select__ seq.rest(), pred
    else if seq.rest()
      @select__ @dropWhile__(seq.rest(), (x) -> not pred x), pred
    else
      null

  @method 'find', (seq, pred) -> (@select__ seq, pred)?.first()

  @method 'forall', (seq, pred) -> not @select__ seq, (x) -> not pred x

  @method 'map', (seq, func) ->
    if @empty__ seq
      null
    else
      Sequence.conj func(seq.first()), => @map__ seq.rest(), func

  @method 'accumulate', (seq, start, op) ->
    if @empty__ seq
      null
    else
      first = op start, seq.first()
      Sequence.conj first, => @accumulate__ seq.rest(), first, op

  @method 'sums',     (seq) -> @accumulate__ seq, 0, (a,b) -> a + b
  @method 'products', (seq) -> @accumulate__ seq, 1, (a,b) -> a * b

  @method 'reduce', (seq, start, op) ->
    if @empty__ seq
      start
    else
      @accumulate__(seq, start, op).last()

  @method 'sum',     (seq) -> @reduce__ seq, 0, (a,b) -> a + b
  @method 'product', (seq) -> @reduce__ seq, 1, (a,b) -> a * b

  @method 'fold', (seq, op) ->
    @reduce__ seq.rest(), seq.first(), op

  @method 'max', (seq) -> @fold__ seq, (a,b) -> if b > a then b else a
  @method 'min', (seq) -> @fold__ seq, (a,b) -> if b < a then b else a

  @operator 'combine', (seq, other, op) ->
    if @empty__ seq
      Sequence.map other, (a) -> op null, a
    else if @empty__ other
      Sequence.map seq, (a) -> op a, null
    else
      Sequence.conj op(seq.first(), other.first()), =>
        @combine__ seq.rest(), other.rest(), op

  @operator 'add', (seq, other) -> @combine__ seq, other, (a,b) -> a + b
  @operator 'sub', (seq, other) -> @combine__ seq, other, (a,b) -> a - b
  @operator 'mul', (seq, other) -> @combine__ seq, other, (a,b) -> a * b
  @operator 'div', (seq, other) -> @combine__ seq, other, (a,b) -> a / b

  @operator 'equals', (seq, other) ->
    not @find__(@combine__(seq, other, (a, b) -> a == b), (a) -> not a)?

  @operator 'interleave', (seq, other) ->
    if @empty__ seq
      other
    else
      Sequence.conj seq.first(), => @interleave__ other, seq.rest()

  @operator 'lazyConcat', (seq, next) ->
    if seq
      Sequence.conj seq.first(), => @lazyConcat__ seq.rest(), next
    else
      next()

  @operator 'concat', (seq, other) ->
    if @empty__ seq
      other
    else
      @lazyConcat__ seq, -> other

  @method 'flatten', (seq) ->
    if @empty__ seq
      null
    else if seq.first()
      @lazyConcat__ make(seq.first()), => @flatten__ seq.rest()
    else if seq.rest()
      @flatten__ @dropWhile__(seq.rest(), (x) -> not make(x)?.first())
    else
      null

  @method 'flatMap', (seq, func) -> @flatten__ @map__ seq, func

  @operator 'cartesian', (seq, other) ->
    @flatMap__ seq, (a) => @map__ other, (b) -> [a,b]

  @method 'each', (seq, func) ->
    step = (s) -> if s then func(s.first()); recur -> step s.rest()
    resolve step seq unless @empty__ seq

  @method 'reverse', (seq) ->
    step = (r, s) =>
      if s then recur => step Sequence.conj(s.first(), -> r), s.rest() else r
    if @empty__ seq then null else resolve step null, seq

  @method 'stored', (seq) ->
    if @empty__ seq
      null
    else
      Sequence.conj seq.first(), (=> @stored__ seq.rest()), 'stored'

  @method 'forced', (seq) ->
    if @empty__ seq
      null
    else
      Sequence.conj seq.first(), (=> @forced__ seq.rest()), 'forced'

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
    '(' + Sequence.into(s, []).join(', ') + if more then ', ...)' else ')'


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sequence = Sequence
