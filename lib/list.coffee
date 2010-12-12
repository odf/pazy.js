# --------------------------------------------------------------------
# Just a regular Lisp-style list class.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

{ recur, resolve } =
  if typeof(require) != 'undefined'
    require.paths.unshift __dirname
    require('trampoline')
  else
    this.pazy


class List
  constructor: (car, cdr) ->
    @[0] = car
    @[1] = cdr

  first: -> @[0]
  rest: -> @[1]

  @fromArray: (a) ->
    step = (r, n) -> if n < 0 then r else recur -> step(new List(a[n], r), n-1)
    resolve step(null, a.length - 1)

  @range: (start, end) ->
    step = (r, n) -> if n < start then r else recur -> step(new List(n, r), n-1)
    resolve step(null, end)

  @cached: (name, code) ->
    @::[name] = -> val = code.apply(this); (@[name] = -> val)()

  @cached 'size', ->
    step = (s, n) -> if s then recur -> step(s[1], n + 1) else n
    resolve step(this, 0)

  @cached 'last', ->
    step = (s) -> if s[1] then recur -> step(s[1]) else s[0]
    resolve step(this)

  drop: (n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s[1], n - 1) else s
    resolve step(this, n)

  get: (n) -> @drop(n)?[0] if n >= 0

  drop_while: (pred) ->
    step = (s) -> if s and pred(s[0]) then recur -> step(s[1]) else s
    resolve step(this)

  each: (func) ->
    step = (s) -> if s then func(s[0]); recur -> step(s[1])
    resolve step(this)

  reverse: ->
    step = (r, s) -> if s then recur -> step(new List(s[0], r), s[1]) else r
    resolve step(null, this)

  map: (func) ->
    step = (r, s) ->
      if s then recur -> step(new List(func(s[0]), r), s[1]) else r
    (resolve step(null, this)).reverse()

  accumulate: (start, op) ->
    step = (r, s) ->
      if s then recur -> step(new List(op(r[0], s[0]), r), s[1]) else r
    (resolve step(new List(start), this)).reverse()[1]

  sums:     -> @accumulate(0, (a,b) -> a + b)
  products: -> @accumulate(1, (a,b) -> a * b)

  reduce: (start, op) ->
    step = (x, s) -> if s then recur -> step(op(x, s[0]), s[1]) else x
    resolve step(start, this)

  sum:     -> @reduce(0, (a,b) -> a + b)
  product: -> @reduce(1, (a,b) -> a * b)

  combine: (other, op) ->
    step = (r, s, t) ->
      if s and t
        recur -> step(new List(op(s[0], t[0]), r), s[1], t[1])
      else
        r
    (resolve step(null, this, other)).reverse()

  plus:  (other) -> @combine(other, (a,b) -> a + b)
  minus: (other) -> @combine(other, (a,b) -> a - b)
  times: (other) -> @combine(other, (a,b) -> a * b)
  by:    (other) -> @combine(other, (a,b) -> a / b)

  equals: (other) ->
    @combine(other, (a,b) -> a == b).reduce(true, (a,b) -> a && b)

  select: (pred) ->
    step = (r, s) ->
      if s
        next = if pred(s[0]) then new List(s[0], r) else r
        recur -> step(next, s[1])
      else
        r
    (resolve step(null, this)).reverse()

  take: (n) ->
    step = (r, s, n) ->
      if s and n > 0 then recur -> step(new List(s[0], r), s[1], n-1) else r
    (resolve step(null, this, n)).reverse()

  take_while: (func) ->
    step = (r, s) ->
      if s and func(s[0]) then recur -> step(new List(s[0], r), s[1]) else r
    (resolve step(null, this)).reverse()

  merge: (other) ->
    step = (r, s, t) ->
      if s
        recur -> step(new List(s[0], r), t, s[1])
      else if t
        recur -> step(new List(t[0], r), null, t[1])
      else
        r
    (resolve step(null, this, other)).reverse()

  concat: (other) ->
    step = (r, s) -> if s then recur -> step(new List(s[0], r), s[1]) else r
    resolve step(other, this.reverse())

  reverse_concat: (other) ->
    step = (r, s) -> if s then recur -> step(new List(s[0], r), s[1]) else r
    resolve step(other, this)

  flatten: ->
    add = (r, s) -> if s then recur -> add new List(s[0], r), s[1] else r
    cat = (r, s) -> if s then recur -> cat (resolve add r, s[0]), s[1] else r
    (resolve cat null, this).reverse()

  flat_map: (func) -> @map(func).flatten()

  cartesian: (other) -> @flat_map((a) -> other.map((b) -> [a,b]))

  toArray: ->
    buffer = []
    @each (x) -> buffer.push(x)
    buffer

  toString: -> "List(#{@toArray().join(', ')})"


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.List = List
