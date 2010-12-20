{ recur, resolve } =
  if typeof(require) != 'undefined'
    require.paths.unshift __dirname
    require('trampoline')
  else
    this.pazy


extend = (base, mixin) -> base[key] = val for key, val of mixin

sequence = (seq) -> sequence.construct seq

extend sequence, {
  construct: (seq) ->
    if seq instanceof Array
      n = seq.length
      partial = (i) => if i < n then @lazyCons seq[i], -> partial(i+1) else null
      partial(0)
    else if typeof seq.first == 'function' and typeof seq.rest == 'function'
      seq
    else if typeof seq.toSequence == 'function'
      seq.toSequence()
    else
      throw new Error "argument #{seq} does not convert to a sequence"

  lazyCons: (first, rest) ->
    first: -> first
    rest:  -> val = rest(); (@rest = -> val)()

  take: (seq, n) ->
    if seq and n > 0
      @lazyCons seq.first(), => @take seq.rest(), n-1
    else
      null

  takeWhile: (seq, pred) ->
    if seq and pred(seq.first())
      @lazyCons seq.first(), => @takeWhile seq.rest(), pred
    else
      null

  drop: (seq, n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s.rest(), n - 1) else s
    resolve step(seq, n)

  dropWhile: (seq, pred) ->
    step = (s) -> if s and pred s.first() then recur -> step s.rest() else s
    resolve step seq

  get: (seq, n) -> @drop(seq, n)?.first() if n >= 0

  select: (seq, pred) ->
    if seq
      if pred seq.first()
        @lazyCons seq.first(), => @select seq.rest(), pred
      else
        @select @dropWhile(seq.rest(), (x) -> not pred x), pred
    else
      null

  map: (seq, func) ->
    if seq
      @lazyCons func(seq.first()), => @map seq.rest(), func
    else
      null

  combine: (seq, other, op) ->
    if seq and other
      @lazyCons op(seq.first(), other.first()), =>
        @combine seq.rest(), other.rest(), op
    else
      null

  plus:  (seq, other) -> @combine seq, other, (a,b) -> a + b
  minus: (seq, other) -> @combine seq, other, (a,b) -> a - b
  times: (seq, other) -> @combine seq, other, (a,b) -> a * b
  by:    (seq, other) -> @combine seq, other, (a,b) -> a / b

  accumulate: (seq, start, op) ->
    if seq
      first = op start, seq.first()
      @lazyCons first, => @accumulate seq.rest(), first, op
    else
      null

  sums:     (seq) -> @accumulate(seq, 0, (a,b) -> a + b)
  products: (seq) -> @accumulate(seq, 1, (a,b) -> a * b)

  merge: (seq, other) ->
    if seq
      @lazyCons seq.first(), => @merge other, seq.rest()
    else
      other

  lazyConcat: (seq, next) ->
    if seq
      @lazyCons seq.first(), => @lazyConcat seq.rest(), next
    else
      next()

  concat: (seq, other) -> @lazyConcat seq, -> other

  flatten: (seq) ->
    if seq
      if seq.first()
        @lazyConcat seq.first(), => @flatten seq.rest()
      else
        @flatten @dropWhile(seq.rest(), (x) -> not x.first())
    else
      null

  flatMap: (seq, func) -> @flatten @map seq, func

  cartesian: (seq, other) -> @flatMap seq, (a) => @map other, (b) -> [a,b]

  toString: (seq) ->
    if seq then "(#{seq.first()}, ...)" else "()"

  toArray: (seq) ->
    buffer = []
    @each seq, (x) -> buffer.push(x)
    buffer

  each: (seq, func) ->
    step = (s) -> if s then func(s.first()); recur -> step(s.rest())
    resolve step(seq)

  reverse: (seq) ->
    step = (r, s) =>
      if s then recur => step(@lazyCons(s.first(), -> r), s.rest()) else r
    resolve step(null, seq)

  size: (seq) ->
    step = (s, n) -> if s then recur -> step s.rest(), n + 1 else n
    resolve step seq, 0

  last: (seq) ->
    step = (s) -> if s.rest() then recur -> step s.rest() else s.first()
    resolve step seq

  from: (start) -> @lazyCons start, => @from start+1

  range: (start, end) -> @take @from(start), end - start + 1
}


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.sequence = sequence

console.log sequence.map sequence.range(101, 110), (n) -> n * n
