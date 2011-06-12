# --------------------------------------------------------------------
# A finger tree implementation.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence } = require('sequence')
else
  { Sequence } = pazy


# A node.
class Node2
  constructor: -> [@a, @b] = arguments
  reduceLeft:  (z, op) -> op(op(z, @a), @b)
  reduceRight: (op, z) -> op(@a, op(@b, z))
  asDigit: -> new Digit2 @a, @b

class Node3
  constructor: -> [@a, @b, @c] = arguments
  reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
  reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))
  asDigit: -> new Digit3 @a, @b, @c

makeNode = (args...) ->
  type = switch args.length
    when 2 then Node2
    when 3 then Node3
    else
      raise new Error "Illegal number of arguments: #{args.length}"

  new type args...


# A digit in a finger tree.
class Digit1
  constructor: -> [@a] = arguments

  reduceLeft:  (z, op) -> op(z, @a)
  reduceRight: (op, z) -> op(@a, z)

  after:  (x) -> new Digit2 x, @a
  before: (x) -> new Digit2 @a, x

  first: -> @a
  last:  -> @a

  rest: -> Empty
  init: -> Empty

class Digit2
  constructor: -> [@a, @b] = arguments

  reduceLeft:  (z, op) -> op(op(z, @a), @b)
  reduceRight: (op, z) -> op(@a, op(@b, z))

  after:  (x) -> new Digit3 x, @a, @b
  before: (x) -> new Digit3 @a, @b, x

  first: -> @a
  last:  -> @b

  rest: -> new Digit1 @b
  init: -> new Digit1 @a

  asNode: -> new Node2 @a, @b

class Digit3
  constructor: -> [@a, @b, @c] = arguments

  reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
  reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))

  after:  (x) -> new Digit4 x, @a, @b, @c
  before: (x) -> new Digit4 @a, @b, @c, x

  first: -> @a
  last:  -> @c

  rest: -> new Digit2 @b, @c
  init: -> new Digit2 @a, @b

  asNode: -> new Node3 @a, @b, @c

class Digit4
  constructor: -> [@a, @b, @c, @d] = arguments

  reduceLeft:  (z, op) -> op(op(op(op(z, @a), @b), @c), @d)
  reduceRight: (op, z) -> op(@a, op(@b, op(@c, op(@d, z))))

  first: -> @a
  last:  -> @d

  rest: -> new Digit3 @b, @c, @d
  init: -> new Digit3 @a, @b, @c

makeDigit = (args...) ->
  type = switch args.length
    when 1 then Digit1
    when 2 then Digit2
    when 3 then Digit3
    when 4 then Digit4
    else
      raise new Error "Illegal number of arguments: #{args.length}"

  new type args...


# An empty finger tree.
Empty = {
  reduceLeft:  (z, op) -> z
  reduceRight: (op, z) -> z

  after:  (a) -> new Single a
  before: (a) -> new Single a

  first: ->
  last:  ->

  rest: ->
  init: ->

  concat: (t) -> t
}


# A finger tree with a single element.
class Single
  constructor: (a) -> @a = a

  reduceLeft:  (z, op) -> op z, @a
  reduceRight: (op, z) -> op @a, z

  after:  (x) -> new Deep makeDigit(x), (-> Empty), makeDigit(@a)
  before: (x) -> new Deep makeDigit(@a), (-> Empty), makeDigit(x)

  first: -> @a
  last:  -> @a

  rest: -> Empty
  init: -> Empty

  concat: (t) -> t.after @a


# A deep finger tree.
class Deep
  reduceLeft  = (op) -> (z, x) -> x.reduceLeft(z, op)
  reduceRight = (op) -> (x, z) -> x.reduceRight(op, z)

  asTree = (s) -> s.reduceLeft Empty, (a, b) -> a.before b
  asSeq  = (s) -> s.reduceRight ((a, b) -> Sequence.conj a, -> b), null

  constructor: (left, mid, right) ->
    @l = left
    @m = -> val = mid(); (@m = -> val)()
    @r = right

  reduceLeft: (z, op0) ->
    op1 = reduceLeft op0
    op2 = reduceLeft op1
    op1(op2(op1(z, @l), @m()), @r)

  reduceRight: (op0, z) ->
    op1 = reduceRight op0
    op2 = reduceRight op1
    op1(@l, op2(@m(), op1(@r, z)))

  after: (x) ->
    if @l.constructor == Digit4
      { a, b, c, d } = @l
      new Deep makeDigit(x, a), (=> @m().after(makeNode(b, c, d))), @r
    else
      new Deep @l.after(x), @m, @r

  before: (x) ->
    if @r.constructor == Digit4
      { a, b, c, d } = @r
      new Deep @l, (=> @m().before(makeNode(a, b, c))), makeDigit(d, x)
    else
      new Deep @l, @m, @r.before(x)

  first: -> @l.first()
  last:  -> @r.last()

  rest: ->
    if  @l.rest() == Empty
      if @m() == Empty
        asTree @r
      else
        new Deep @m().first().asDigit(), (=> @m().rest()), @r
    else
      new Deep @l.rest(), @m, @r

  init: ->
    if  @r.init() == Empty
      if @m() == Empty
        asTree @l
      else
        new Deep @l, (=> @m().init()), @m().last().asDigit()
    else
      new Deep @l, @m, @r.init()

  nodes = (n, s) ->
    if n == 0
      null
    else if n == 2 or n % 3 == 1
      Sequence.conj new Node2(s.take(3).into([])...), -> nodes n-2, s.drop 2
    else if n >= 3
      Sequence.conj new Node3(s.take(3).into([])...), -> nodes n-3, s.drop 3
    else
      raise new Error "this should not happen"

  app3 = (tLeft, list, tRight) ->
    if tLeft == Empty
      Sequence.reduce Sequence.reverse(list), tRight, (t, x) -> t.after x
    else if tRight == Empty
      Sequence.reduce list, tLeft, (t, x) -> t.before x
    else if tLeft.constructor == Single
      app3(Empty, list, tRight).after tLeft.a
    else if tRight.constructor == Single
      app3(tLeft, list, Empty).before tRight.a
    else
      tmp = Sequence.flatten [asSeq(tLeft.r), list,  asSeq(tRight.l)]
      s = nodes tmp.size(), tmp
      new Deep tLeft.l, (-> app3 tLeft.m(), s, tRight.m()), tRight.r

  concat: (t) -> app3 this, null, t


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.Empty = Empty
