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

  @cached: (name, code) ->
    @::[name] = -> val = code.apply(this); (@[name] = -> val)()

  @fromArray: (a) ->
    step = (r, n) -> if n < 0 then r else recur -> step(new List(a[n], r), n-1)
    resolve step(null, a.length - 1)

  @range: (start, end) ->
    step = (r, n) -> if n < start then r else recur -> step(new List(n, r), n-1)
    resolve step(null, end)

  drop: (n) ->
    step = (s, n) -> if s and n > 0 then recur -> step(s[1], n - 1) else s
    resolve step(this, n)

  get: (n) -> @drop(n)[0]

  drop_while: (pred) ->
    step = (s) -> if s and pred(s[0]) then recur -> step(s[1]) else s
    resolve step(this)

  each: (func) ->
    step = (s) -> if s then func(s[0]); recur -> step(s[1])
    resolve step(this)

  map: (func) ->
    step = (r, s) ->
      if s then recur -> step(new List(func(s[0]), r), s[1]) else r
    resolve step(null, this.reverse())

  select: (pred) ->
    step = (r, s) ->
      if s
        next = if pred(s[0]) then new List(s[0], r) else r
        recur -> step(next, s[1])
      else
        r
    resolve step(null, this.reverse())

  @cached 'reverse', ->
    step = (r, s) -> if s then recur -> step(new List(s[0], r), s[1]) else r
    resolve step(null, this)

  @cached 'size', ->
    step = (s, n) -> if s then recur -> step(s[1], n + 1) else n
    resolve step(this, 0)

  @cached 'last', ->
    step = (s) -> if s[1] then recur -> step(s[1]) else s[0]
    resolve step(this)

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
