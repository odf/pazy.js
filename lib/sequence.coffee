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
  constructor: (@first, @rest) ->

  @conj: (first, rest = (-> null), mode = null) ->
    if mode == 'forced'
      r = rest()
      new Sequence (-> first), -> r
    else
      new Sequence (-> first), -> val = rest(); (@rest = -> val)()

  @from: (start) -> Sequence.conj start, => @from start+1

  @range: (start, end) -> @take__ @from(start), end - start + 1

  @constant: (value) -> Sequence.conj value, => @constant value

  @::S__ = this

  @memo: (name, f) ->
    @[name]        = (s) -> f.call this, seq s
    @["#{name}__"] = (s) -> f.call this, s
    @::[name]      =     -> x = f.call(@S__, this); (@[name] = -> x)()

  @method: (name, f) ->
    @[name]        = (s, args...) -> f.call(this, seq(s), args...)
    @["#{name}__"] = (s, args...) -> f.call(this, s,      args...)
    @::[name]      = (args...)    -> f.call(@S__, this,   args...)

  @operator: (name, f) ->
    @[name]        = (s, t, args...) -> f.call(this, seq(s), seq(t), args...)
    @["#{name}__"] = (s, t, args...) -> f.call(this, s,      t,      args...)
    @::[name]      = (t, args...)    -> f.call(@S__, this,   seq(t), args...)

  @method 'empty', (s) -> not s?

  @memo 'size', (s) ->
    step = (t, n) -> if t then recur -> step t.rest(), n + 1 else n
    resolve step s, 0

  @memo 'last', (s) ->
    step = (t) -> if t.rest() then recur -> step t.rest() else t.first()
    if s then resolve step s

  @method 'take', (s, n) ->
    if s and n > 0
      Sequence.conj s.first(), => @take__ s.rest(), n-1
    else
      null

  @method 'takeWhile', (s, pred) ->
    if s and pred s.first()
      Sequence.conj s.first(), => @takeWhile__ s.rest(), pred
    else
      null

  @method 'drop', (s, n) ->
    step = (t, n) -> if t and n > 0 then recur -> step t.rest(), n - 1 else t
    if s then resolve step s, n else null

  @method 'dropWhile', (s, pred) ->
    step = (t) -> if t and pred t.first() then recur -> step t.rest() else s
    if s then resolve step s else null

  @method 'get', (s, n) -> if n >= 0 then @drop__(s, n)?.first()

  @method 'select', (s, pred) ->
    if s and pred s.first()
      Sequence.conj s.first(), => @select__ s.rest(), pred
    else if s?.rest()
      @select__ @dropWhile__(s.rest(), (x) -> not pred x), pred
    else
      null

  @method 'find', (s, pred) -> (@select__ s, pred)?.first()

  @method 'forall', (s, pred) -> not @select__ s, (x) -> not pred x

  @method 'map', (s, func) ->
    if s
      Sequence.conj func(s.first()), => @map__ s.rest(), func
    else
      null

  @method 'accumulate', (s, start, op) ->
    if s
      first = op start, s.first()
      Sequence.conj first, => @accumulate__ s.rest(), first, op
    else
      null

  @method 'sums',     (s) -> @accumulate__ s, 0, (a,b) -> a + b
  @method 'products', (s) -> @accumulate__ s, 1, (a,b) -> a * b

  @method 'reduce', (s, start, op) ->
    step = (t, val) ->
      if t then recur -> step t.rest(), op val, t.first() else val
    if s then resolve step s, start else start

  @method 'sum',     (s) -> @reduce__ s, 0, (a,b) -> a + b
  @method 'product', (s) -> @reduce__ s, 1, (a,b) -> a * b

  @method 'fold', (s, op) -> @reduce__ s?.rest(), s?.first(), op

  @method 'max', (s) -> @fold__ s, (a,b) -> if b > a then b else a
  @method 'min', (s) -> @fold__ s, (a,b) -> if b < a then b else a

  @operator 'combine', (s, t, op) ->
    if not s
      Sequence.map t, (a) -> op null, a
    else if not t
      Sequence.map s, (a) -> op a, null
    else
      Sequence.conj op(s.first(), t.first()), =>
        @combine__ s.rest(), t.rest(), op

  @operator 'add', (s, t) -> @combine__ s, t, (a,b) -> a + b
  @operator 'sub', (s, t) -> @combine__ s, t, (a,b) -> a - b
  @operator 'mul', (s, t) -> @combine__ s, t, (a,b) -> a * b
  @operator 'div', (s, t) -> @combine__ s, t, (a,b) -> a / b

  @operator 'equals', (s, t) ->
    not @find__(@combine__(s, t, (a, b) -> a == b), (a) -> not a)?

  @operator 'interleave', (s, t) ->
    if s
      Sequence.conj s.first(), => @interleave__ t, s.rest()
    else
      t

  @operator 'lazyConcat', (s, next) ->
    if s
      Sequence.conj s.first(), => @lazyConcat__ s.rest(), next
    else
      next()

  @operator 'concat', (s, t) ->
    if s
      @lazyConcat__ s, -> t
    else
      t

  @method 'flatten', (s) ->
    if s and seq s.first()
      @lazyConcat__ seq(s.first()), => @flatten__ s.rest()
    else if s?.rest()
      @flatten__ @dropWhile__ s.rest(), (x) -> not seq x
    else
      null

  @method 'flatMap', (s, func) -> @flatten__ @map__ s, func

  @operator 'cartesian', (s, t) -> @flatMap__ s, (a) => @map__ t, (b) -> [a,b]

  @method 'each', (s, func) ->
    step = (t) -> if t then func(t.first()); recur -> step t.rest()
    if s then resolve step s

  @method 'reverse', (s) ->
    step = (r, t) =>
      if t then recur => step Sequence.conj(t.first(), -> r), t.rest() else r
    if s then resolve step null, s else null

  @method 'forced', (s) ->
    if s
      Sequence.conj s.first(), (=> @forced__ s.rest()), 'forced'
    else
      null

  @method 'into', (s, target) ->
    if not target?
      @reduce__ s, null, (s, item) -> Sequence.conj item, -> s
    else if typeof target.plus == 'function'
      @reduce__ s, target, (t, item) -> t.plus item
    else if typeof target.length == 'number'
      a = (x for x in target)
      @each__ s, (x) -> a.push x
      a
    else
      throw new Error('cannot inject into #{target}')

  @method 'join', (s, glue) -> @into__(s, []).join glue

  @method 'toString', (s, limit = 10) ->
    [t, more] = if limit > 0
      [@take__(s, limit), @get__(s, limit)?]
    else
      [s, false]
    '(' + Sequence.join(t, ', ') + if more then ', ...)' else ')'


skip = (a, i) ->
  if i >= a.length or a[i] != undefined
    fromArray a, i
  else
    recur -> skip a, i+1

fromArray = (a, i) ->
  if i >= a.length
    null
  else if a[i] == undefined
    resolve skip a, i
  else
    Sequence.conj a[i], -> fromArray a, i+1


seq = (src) ->
  if not src?
    null
  else if typeof src.toSeq == 'function'
    src.toSeq()
  else if typeof src.first == 'function' and typeof src.rest == 'function'
    Sequence.conj src.first(), src.rest
  else if typeof src.length == 'number'
    fromArray src, 0
  else
    throw new Error("cannot make a sequence from #{src}")


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sequence = Sequence
exports.seq = seq
