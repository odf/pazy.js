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
  constructor: (source) ->
    if source instanceof Array
      n = source.length
      partial = (i) =>
        if i < n then Sequence.conj source[i], -> partial(i+1) else null
      @first = -> source[0]
      @rest  = -> partial(1)
    else if typeof source.toSequence == 'function'
      seq = source.toSequence()
      @first = seq.first
      @rest  = seq.rest
    else
      @first = source.first
      @rest  = source.rest

  @conj: (first, rest, mode) ->
    r = rest() if mode == 'forced'
    new Sequence {
      first: -> first
      rest:
        switch mode
          when 'stored' then -> val = rest(); (@rest = -> val)()
          when 'forced' then -> r
          else               -> rest()
    }

  @from: (start) -> Sequence.conj start, => @from start+1

  @range: (start, end) -> @take__ @from(start), end - start + 1

  @::S = this

  @memo: (name, f) ->
    @[name]        = (seq) -> f.call(this, new Sequence(seq))
    @["#{name}__"] = (seq) -> f.call(this, seq)
    @::[name]      = -> x = f.call(@S, this); (@[name] = -> x)()

  @method: (name, f) ->
    @[name]        = (seq, args...) -> f.call(this, new Sequence(seq), args...)
    @["#{name}__"] = (seq, args...) -> f.call(this, seq, args...)
    @::[name]      = (args...) -> f.call(@S, this, args...)

  @operator: (name, f) ->
    @[name]        = (seq, other, args...) ->
      f(new Sequence(seq), new Sequence(other), args...)
    @["#{name}__"] = (seq, other, args...) ->
      f.call(this, seq, other, args...)
    @::[name]      = (other, args...) ->
      f.call(@S, this, new Sequence(other), args...)

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

  select: (pred) ->
    if pred @first()
      Sequence.conj @first(), => @rest()?.select pred
    else if @rest()
      @rest().dropWhile((x) -> not pred x)?.select pred
    else
      null

  find: (pred) -> @select(pred)?.first()

  forall: (pred) -> not @find (x) -> not pred x

  map: (func) -> Sequence.conj func(@first()), => @rest()?.map func

  accumulate: (start, op) ->
    first = op start, @first()
    Sequence.conj first, => @rest()?.accumulate first, op

  sums:     -> @accumulate(0, (a,b) -> a + b)
  products: -> @accumulate(1, (a,b) -> a * b)

  reduce: (start, op) -> @accumulate(start, op).last()

  sum:     -> @reduce(0, (a,b) -> a + b)
  product: -> @reduce(1, (a,b) -> a * b)

  combine: (other, op) ->
    Sequence.conj op(this.first(), other.first()), =>
      if this.rest() and other.rest()
        this.rest().combine other.rest(), op

  plus:  (other) -> @combine(other, (a,b) -> a + b)
  minus: (other) -> @combine(other, (a,b) -> a - b)
  times: (other) -> @combine(other, (a,b) -> a * b)
  by:    (other) -> @combine(other, (a,b) -> a / b)

  equals: (other) ->
    @combine(other, (a,b) -> a == b).reduce true, (a,b) -> a && b

  merge: (other) ->
    Sequence.conj @first(), => if other then other.merge @rest() else @rest()

  lazyConcat: (next) ->
    Sequence.conj @first(), => if @rest() then @rest().lazyConcat(next) else next()

  concat: (other) -> @lazyConcat -> other

  flatten: ->
    if @first()
      @first().lazyConcat => @rest()?.flatten()
    else if @rest()
      @rest().dropWhile((x) -> not x.first()).flatten()
    else
      null

  flatMap: (func) -> @map(func).flatten()

  cartesian: (other) -> @flatMap (a) -> other.map (b) -> [a,b]

  toString: -> "Sequence(#{@first()}, ...)"

  toArray: ->
    buffer = []
    @each (x) -> buffer.push x
    buffer

  each: (func) ->
    step = (s) -> if s then func(s.first()); recur -> step(s.rest())
    resolve step this

  reverse: ->
    step = (r, s) =>
      if s then recur => step Sequence.conj(s.first(), -> r), s.rest() else r
    resolve step null, this

  stored: -> Sequence.conj @first(), (=> @rest()?.stored()), 'stored'

  forced: -> Sequence.conj @first(), (=> @rest()?.forced()), 'forced'


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sequence = Sequence
