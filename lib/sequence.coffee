if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require('trampoline')
else
  { recur, resolve } = this.pazy


lazyCons = (first, rest) ->
  new Sequence {
    first: -> first
    rest:  -> rest()
  }

streamCons = (first, rest) ->
  new Sequence {
    first: -> first
    rest:  -> val = rest(); (@rest = -> val)()
  }


class Sequence
  constructor: (source) ->
    if source instanceof Array
      n = source.length
      partial = (i) =>
        if i < n then lazyCons source[i], -> partial(i+1) else null
      @first = -> source[0]
      @rest  = -> partial(1)
    else if typeof source.toSequence == 'function'
      seq = source.toSequence()
      @first = seq.first
      @rest  = seq.rest
    else
      @first = source.first
      @rest  = source.rest

  take: (n) ->
    if n > 0
      lazyCons @first(), => @rest()?.take n-1
    else
      null

  takeWhile: (pred) ->
    if pred(@first())
      lazyCons @first(), => @rest()?.takeWhile pred
    else
      null

  drop: (n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s.rest(), n - 1) else s
    resolve step this, n

  dropWhile: (pred) ->
    step = (s) -> if s and pred s.first() then recur -> step s.rest() else s
    resolve step this

  get: (n) -> @drop(n)?.first() if n >= 0

  select: (pred) ->
    if pred @first()
      lazyCons @first(), => @rest()?.select pred
    else if @rest()
      @rest().dropWhile((x) -> not pred x)?.select pred
    else
      null

  find: (pred) -> @select(pred)?.first()

  forall: (pred) -> not @find (x) -> not pred x

  map: (func) -> lazyCons func(@first()), => @rest()?.map func

  accumulate: (start, op) ->
    first = op start, @first()
    lazyCons first, => @rest()?.accumulate first, op

  sums:     -> @accumulate(0, (a,b) -> a + b)
  products: -> @accumulate(1, (a,b) -> a * b)

  reduce: (start, op) -> @accumulate(start, op).last()

  sum:     -> @reduce(0, (a,b) -> a + b)
  product: -> @reduce(1, (a,b) -> a * b)

  combine: (other, op) ->
    lazyCons op(this.first(), other.first()), =>
      if this.rest() and other.rest()
        this.rest().combine other.rest(), op

  plus:  (other) -> @combine(other, (a,b) -> a + b)
  minus: (other) -> @combine(other, (a,b) -> a - b)
  times: (other) -> @combine(other, (a,b) -> a * b)
  by:    (other) -> @combine(other, (a,b) -> a / b)

  equals: (other) ->
    @combine(other, (a,b) -> a == b).reduce true, (a,b) -> a && b

  merge: (other) ->
    lazyCons @first(), => if other then other.merge @rest() else @rest()

  lazyConcat: (next) ->
    lazyCons @first(), => if @rest() then @rest().lazyConcat(next) else next()

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
      if s then recur => step lazyCons(s.first(), -> r), s.rest() else r
    resolve step null, this

  stored: -> streamCons @first(), => @rest().stored()

  @memo: (name, f) -> @::[name] = -> x = f.apply(this); (@[name] = -> x)()

  @memo 'size', ->
    step = (s, n) -> if s then recur -> step s.rest(), n + 1 else n
    resolve step this, 0

  @memo 'last', ->
    step = (s) -> if s.rest() then recur -> step s.rest() else s.first()
    resolve step this

  @make: lazyCons

  @from: (start) -> lazyCons start, => @from start+1

  @range: (start, end) -> @from(start).take end - start + 1


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Sequence = Sequence
