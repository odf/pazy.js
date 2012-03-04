# --------------------------------------------------------------------
# A sequence class vaguely inspired by Clojure's sequences.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

#TODO catch missing return values from function arguments

if typeof(require) != 'undefined'
  { equal }  = require 'core_extensions'
  { bounce } = require('functional')
else
  { equal, bounce } = this.pazy


class Sequence
  constructor: (@first, @rest) ->


skip = (a, i) ->
  if i >= a.length or a[i] != undefined
    fromArray a, i
  else
    -> skip a, i+1

fromArray = (a, i) ->
  if i >= a.length
    null
  else if a[i] == undefined
    bounce skip a, i
  else
    seq.conj a[i], -> fromArray a, i+1

seq = (src) ->
  if not src?
    null
  else if src.constructor == Sequence
    src
  else if typeof src.toSeq == 'function'
    src.toSeq()
  else if typeof src.length == 'number'
    fromArray src, 0
  else if typeof src.first == 'function' and typeof src.rest == 'function'
    src
  else
    throw new Error("cannot make a sequence from #{src}")


seq.conj = (first, rest, mode) ->
  if not rest?
    new Sequence (-> first), -> null
  else if mode == 'forced'
    r = rest()
    new Sequence (-> first), -> r
  else
    new Sequence (-> first), -> val = rest(); (@rest = -> val)()

seq.from = (start) -> seq.conj start, => seq.from start+1

seq.range = (start, end) -> seq.take__ seq.from(start), end - start + 1

seq.constant = (value) -> seq.conj value, => seq.constant value


seq.memo = memo = (name, f) ->
  seq[name]        = (s) -> f.call seq, seq s
  seq["#{name}__"] = (s) -> f.call seq, s
  Sequence::[name] = -> x = f.call(seq, this); (@[name] = -> x)()

seq.method = method = (name, f) ->
  seq[name]        = (s, args...) -> f.call(seq, seq(s), args...)
  seq["#{name}__"] = (s, args...) -> f.call(seq, s,      args...)
  Sequence::[name] = (args...)    -> f.call(seq, this,   args...)

seq.combinator = combinator = (name, f) ->
  namex = "#{name}__"
  seq[namex]       = (seqs)    -> f.call seq, seqs
  seq[name]        = (args...) -> seq[namex] seq.map args, seq
  Sequence::[name] = (args...) -> seq[name] this, args...

method 'empty', (s) -> not s?

memo 'size', (s) ->
  step = (t, n) -> if t then -> step t.rest(), n + 1 else n
  bounce step s, 0

memo 'last', (s) ->
  step = (t) -> if t.rest() then -> step t.rest() else t.first()
  if s then bounce step s

method 'take', (s, n) ->
  if s and n > 0
    @conj s.first(), => @take__ s.rest(), n-1
  else
    null

method 'takeWhile', (s, pred) ->
  if s and pred s.first()
    @conj s.first(), => @takeWhile__ s.rest(), pred
  else
    null

method 'drop', (s, n) ->
  step = (t, n) -> if t and n > 0 then -> step t.rest(), n - 1 else t
  if s then bounce step s, n else null

method 'dropWhile', (s, pred) ->
  step = (t) -> if t and pred t.first() then -> step t.rest() else t
  if s then bounce step s else null

method 'get', (s, n) -> if n >= 0 then @drop__(s, n)?.first()

method 'select', (s, pred) ->
  if s and pred s.first()
    @conj s.first(), => @select__ s.rest(), pred
  else if s?.rest()
    @select__ @dropWhile__(s.rest(), (x) -> not pred x), pred
  else
    null

method 'find', (s, pred) -> (@select__ s, pred)?.first()

method 'forall', (s, pred) -> not @select__ s, (x) -> not pred x

method 'map', (s, func) ->
  if s
    @conj func(s.first()), => @map__ s.rest(), func
  else
    null

method 'accumulate', (s, start, op) ->
  if s
    first = op start, s.first()
    @conj first, => @accumulate__ s.rest(), first, op
  else
    null

method 'sums',     (s) -> @accumulate__ s, 0, (a,b) -> a + b
method 'products', (s) -> @accumulate__ s, 1, (a,b) -> a * b

method 'reduce', (s, start, op) ->
  step = (t, val) -> if t then -> step t.rest(), op val, t.first() else val
  bounce step s, start

method 'sum',     (s) -> @reduce__ s, 0, (a,b) -> a + b
method 'product', (s) -> @reduce__ s, 1, (a,b) -> a * b

method 'fold', (s, op) -> @reduce__ s?.rest(), s?.first(), op

method 'max', (s) -> @fold__ s, (a,b) -> if b > a then b else a
method 'min', (s) -> @fold__ s, (a,b) -> if b < a then b else a

combinator 'zip', (seqs) ->
  firsts = seqs?.map (s) -> if s? then s.first() else null
  if seq.find(firsts, (x) -> x?)?
    seq.conj firsts, -> seq.zip__ seq.map seqs, (s) -> s?.rest()
  else
    null

seq.combine       = (op, args...) -> seq.zip(args...)?.map (s) -> seq.fold s, op
Sequence::combine = (op, args...) -> seq.combine op, this, args...

method 'add', (s, args...) -> seq.combine ((a, b) -> a + b), s, args...
method 'sub', (s, args...) -> seq.combine ((a, b) -> a - b), s, args...
method 'mul', (s, args...) -> seq.combine ((a, b) -> a * b), s, args...
method 'div', (s, args...) -> seq.combine ((a, b) -> a / b), s, args...

method 'equals', (s, args...) ->
  @forall__ seq.zip(s, args...), (t) ->
    x = t?.first()
    seq.forall__ t?.rest(), (y) -> equal x, y

method 'lazyConcat', (s, t) ->
  if s
    @conj s.first(), => @lazyConcat s.rest(), t
  else
    seq t()

combinator 'concat', (seqs) ->
  if seqs
    @lazyConcat seqs.first(), => @concat__ seqs.rest()
  else
    null

combinator 'interleave', (seqs) ->
  live = seqs?.select (s) -> s?
  if live?
    firsts = live.map((s) -> s.first())
    @lazyConcat firsts, => @interleave__ live.map (s) -> s.rest()
  else
    null

method 'flatten', (s) ->
  if s and seq s.first()
    @lazyConcat seq(s.first()), => @flatten__ s.rest()
  else if s?.rest()
    @flatten__ @dropWhile__ s.rest(), (x) -> not seq x
  else
    null

method 'flatMap', (s, func) -> @flatten__ @map__ s, func

combinator 'cartesian', (seqs) ->
  if seqs
    if seqs.rest()
      @flatMap__ seqs.first(), (a) =>
        @cartesian__(seqs.rest())?.map (s) => @conj a, -> s
    else
      seqs.first().map seq.conj
  else
    null

cantor_fold = (s, back, remaining) ->
  if remaining
    t = seq.conj remaining.first(), -> back
    z = s.zip(t).takeWhile((x) -> x?.get(1)).flatMap (x) ->
      a = x.first()
      x.get(1).map (y) -> seq.conj a, -> y
    seq.conj z, -> cantor_fold s, t, remaining.rest()
  else
    null

cantor_runs = (seqs) ->
  if seqs
    if seqs.rest()
      cantor_fold seqs.first(), null, cantor_runs seqs.rest()
    else
      seqs.first().map (x) -> seq.conj seq.conj x
  else
    null

combinator 'cantor', (seqs) -> cantor_runs(seqs)?.flatten()

method 'subseqs', (s) ->
  if s
    @conj s, => @subseqs__ s.rest()
  else
    null

method 'each', (s, func) ->
  step = (t) -> if t then func(t.first()); -> step t.rest()
  bounce step s

method 'reverse', (s) ->
  step = (r, t) => if t then => step @conj(t.first(), -> r), t.rest() else r
  bounce step null, s

method 'forced', (s) ->
  if s
    @conj s.first(), (=> @forced__ s.rest()), 'forced'
  else
    null

method 'into', (s, target) ->
  if not target?
    s
  else if typeof target.plus == 'function'
    @reduce__ s, target, (t, item) -> t.plus item
  else if typeof target.length == 'number'
    a = (x for x in target)
    @each__ s, (x) -> a.push x
    a
  else
    throw new Error('cannot inject into #{target}')

method 'join', (s, glue) -> @into__(s, []).join glue

method 'toString', (s, limit = 10) ->
  [t, more] = if limit > 0
    [@take__(s, limit), @get__(s, limit)?]
  else
    [s, false]
  '(' + @join__(t, ', ') + if more then ', ...)' else ')'


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.seq = seq


# --------------------------------------------------------------------
# Quick testing.
# --------------------------------------------------------------------

if module? and not module.parent
  s = seq.from(1)
  console.log "#{s.cantor(s, s).take 10}"
