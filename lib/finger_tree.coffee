# --------------------------------------------------------------------
# A finger tree implementation.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift('#{__dirname}/../lib')
  { Sequence }                = require('sequence')
  { recur, resolve, suspend } = require('functional')
else
  { Sequence, recur, resolve, suspend } = pazy


class FingerTreeType
  constructor: (measure, extensions) ->
    @buildLeft = @build = ->
      new Instance Sequence.reduce arguments, Empty, (s, a) -> s.before a

    @buildRight = ->
      new Instance Sequence.reduce arguments, Empty, (s, a) -> s.after a

    single = (x) -> if x == Empty or x.constructor in internal
        x.measure()
      else
        measure.single(x)

    norm = -> Sequence.reduce arguments, measure.empty, (n, x) ->
      if x? then measure.sum n, single x else n

    rev = (x) -> if x?.constructor in [Node2, Node3] then x.reverse() else x


    # Wrapper for finger tree instances
    class Instance extends extensions
      constructor: (@data) ->

      isEmpty: -> @data.isEmpty()

      reduceLeft:  (z, op) -> @data.reduceLeft z, op
      reduceRight: (op, z) -> @data.reduceRight op, z

      after:  (x) -> if x == undefined then @ else new Instance @data.after x
      before: (x) -> if x == undefined then @ else new Instance @data.before x

      first: -> @data.first()
      last:  -> @data.last()

      rest: -> new Instance @data.rest()
      init: -> new Instance @data.init()

      concat: (t) -> if not t? then this else new Instance @data.concat t.data

      measure: -> @data.measure()

      split: (p) ->
        if @data != Empty and p norm @data
          [l, x, r] = @data.split p, measure.empty
          [new Instance(l), x, new Instance(r)]
        else
          [this, undefined, new Instance(Empty)]

      reverse: -> new Instance @data.reverse()

      takeUntil: (p) -> @split(p)[0]
      dropUntil: (p) -> [l, x, r] = @split(p); r.after x
      find:      (p) -> @split(p)[1]

      toString: -> @data.reduceLeft "", (s, x) -> s + x


    # A node.
    class Node2
      constructor: (@a, @b) -> @v = norm @a, @b

      reduceLeft:  (z, op) -> op(op(z, @a), @b)
      reduceRight: (op, z) -> op(@a, op(@b, z))
      asDigit: -> new Digit2 @a, @b
      measure: -> @v
      reverse: -> new Node2 rev(@b), rev(@a)

    class Node3
      constructor: (@a, @b, @c) -> @v = norm @a, @b, @c

      reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
      reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))
      asDigit: -> new Digit3 @a, @b, @c
      measure: -> @v
      reverse: -> new Node3 rev(@c), rev(@b), rev(@a)


    # A digit in a finger tree.
    class Digit1
      constructor: (@a) ->

      reduceLeft:  (z, op) -> op(z, @a)
      reduceRight: (op, z) -> op(@a, z)

      after:  (x) -> new Digit2 x, @a
      before: (x) -> new Digit2 @a, x

      first: -> @a
      last:  -> @a

      rest: -> Empty
      init: -> Empty

      measure: -> norm @a

      split: (p, i) -> [Empty, @a, Empty]

      reverse: -> new Digit1 rev(@a)

    class Digit2
      constructor: (@a, @b) ->

      reduceLeft:  (z, op) -> op(op(z, @a), @b)
      reduceRight: (op, z) -> op(@a, op(@b, z))

      after:  (x) -> new Digit3 x, @a, @b
      before: (x) -> new Digit3 @a, @b, x

      first: -> @a
      last:  -> @b

      rest: -> new Digit1 @b
      init: -> new Digit1 @a

      asNode: -> new Node2 @a, @b

      measure: -> norm @a, @b

      split: (p, i) ->
        if p measure.sum i, norm @a
          [Empty, @a, new Digit1(@b)]
        else
          [new Digit1(@a), @b, Empty]

      reverse: -> new Digit2 rev(@b), rev(@a)

    class Digit3
      constructor: (@a, @b, @c) ->

      reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
      reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))

      after:  (x) -> new Digit4 x, @a, @b, @c
      before: (x) -> new Digit4 @a, @b, @c, x

      first: -> @a
      last:  -> @c

      rest: -> new Digit2 @b, @c
      init: -> new Digit2 @a, @b

      asNode: -> new Node3 @a, @b, @c

      measure: -> norm @a, @b, @c

      split: (p, i) ->
        i1 = measure.sum i, norm @a
        if p i1
          [Empty, @a, new Digit2(@b, @c)]
        else if p measure.sum i1, norm @b
          [new Digit1(@a), @b, new Digit1(@c)]
        else
          [new Digit2(@a, @b), @c, Empty]

      reverse: -> new Digit3 rev(@c), rev(@b), rev(@a)

    class Digit4
      constructor: (@a, @b, @c, @d) ->

      reduceLeft:  (z, op) -> op(op(op(op(z, @a), @b), @c), @d)
      reduceRight: (op, z) -> op(@a, op(@b, op(@c, op(@d, z))))

      first: -> @a
      last:  -> @d

      rest: -> new Digit3 @b, @c, @d
      init: -> new Digit3 @a, @b, @c

      measure: -> norm @a, @b, @c, @d

      split: (p, i) ->
        i1 = measure.sum i, norm @a
        if p i1
          [Empty, @a, new Digit3(@b, @c, @d)]
        else
          i2 = measure.sum i1, norm @b
          if p i2
            [new Digit1(@a), @b, new Digit2(@c, @d)]
          else if p measure.sum i2, norm @c
            [new Digit2(@a, @b), @c, new Digit1(@d)]
          else
            [new Digit3(@a, @b, @c), @d, Empty]

      reverse: -> new Digit4 rev(@d), rev(@c), rev(@b), rev(@a)


    # An empty finger tree.
    Empty = {
      isEmpty: -> true

      reduceLeft:  (z, op) -> z
      reduceRight: (op, z) -> z

      after:  (a) -> new Single a
      before: (a) -> new Single a

      first: ->
      last:  ->

      rest: ->
      init: ->

      concat: (t) -> t

      measure: -> norm()

      reverse: -> this
    }


    # A finger tree with a single element.
    class Single
      constructor: (@a) ->

      isEmpty: -> false

      reduceLeft:  (z, op) -> op z, @a
      reduceRight: (op, z) -> op @a, z

      after:  (x) -> new Deep new Digit1(x), (-> Empty), new Digit1(@a)
      before: (x) -> new Deep new Digit1(@a), (-> Empty), new Digit1(x)

      first: -> @a
      last:  -> @a

      rest: -> Empty
      init: -> Empty

      concat: (t) -> t.after @a

      measure: -> norm @a

      split: (p, i) -> [Empty, @a, Empty]

      reverse: -> this


    # A deep finger tree.
    class Deep
      reduceLeft  = (op) -> (z, x) -> x.reduceLeft(z, op)
      reduceRight = (op) -> (x, z) -> x.reduceRight(op, z)

      asTree = (s) -> s.reduceLeft Empty, (a, b) -> a.before b
      asSeq  = (s) -> s.reduceRight ((a, b) -> Sequence.conj a, -> b), null

      constructor: (@l, m, @r) -> @m = -> val = m(); (@m = -> val)()

      isEmpty: -> false

      measure: -> val = norm(@l, @m(), @r); (@measure = -> val)()

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
          new Deep new Digit2(x, a), (=> @m().after(new Node3(b, c, d))), @r
        else
          new Deep @l.after(x), @m, @r

      before: (x) ->
        if @r.constructor == Digit4
          { a, b, c, d } = @r
          new Deep @l, (=> @m().before(new Node3(a, b, c))), new Digit2(d, x)
        else
          new Deep @l, @m, @r.before(x)

      first: -> @l.first()
      last:  -> @r.last()

      deepL = (l, m, r) ->
        if l == Empty
          if m() == Empty
            asTree r
          else
            new Deep m().first().asDigit(), (=> m().rest()), r
        else
          new Deep l, m, r

      deepR = (l, m, r) ->
        if  r == Empty
          if m() == Empty
            asTree l
          else
            new Deep l, (=> m().init()), m().last().asDigit()
        else
          new Deep l, m, r

      rest: -> deepL @l.rest(), suspend(=> @m()), @r
      init: -> deepR @l, suspend(=> @m()), @r.init()

      nodes = (n, s) ->
        if n == 0
          null
        else if n == 1 or n < 0
          throw new Error "this should not happen"
        else if n == 2 or n % 3 == 1
          Sequence.conj new Node2(s.take(2).into([])...), -> nodes n-2, s.drop 2
        else
          Sequence.conj new Node3(s.take(3).into([])...), -> nodes n-3, s.drop 3

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

      split: (p, i) ->
        i1 = measure.sum i, norm @l
        if p i1
          [l, x, r] = @l.split p, i
          [asTree(l), x, deepL(r, suspend(=> @m()), @r)]
        else
          i2 = measure.sum i1, norm @m()
          if p i2
            [ml, xs, mr] = @m().split p, i1
            [l, x, r] = xs.asDigit().split p, measure.sum i1, norm ml
            [deepR(@l, (-> ml), l), x, deepL(r, (-> mr), @r)]
          else
            [l, x, r] = @r.split p, i2
            [deepR(@l, suspend(=> @m()), l), x, asTree(r)]

      reverse: -> new Deep @r.reverse(), suspend(=> @m().reverse()), @l.reverse()

    internal = [
      Node2
      Node3
      Digit1
      Digit2
      Digit3
      Digit4
      Single
      Deep
    ]


# --------------------------------------------------------------------
# Specialisations
# --------------------------------------------------------------------

SizeMeasure =
  empty:  0
  single: (x) -> 1
  sum:    (a, b) -> a + b

class CountedExtensions
  size: -> @measure()
  get: (i) -> @find (m) -> m > i
  splitAt: (i) -> [l, x, r] = @split((m) -> m > i); [l, r.after x]

CountedSeq = new FingerTreeType SizeMeasure, CountedExtensions


OrderMeasure =
  empty:  undefined
  single: (x) -> x
  sum:    (a, b) -> if b? then b else a

class SortedExtensions

SortedSeq = (->
  class Instance
    constructor: (@data) ->

    isEmpty: -> @data.isEmpty()

    reduceLeft:  (z, op) -> @data.reduceLeft z, op
    reduceRight: (op, z) -> @data.reduceRight op, z

    first: -> @data.first()
    last:  -> @data.last()

    rest: -> new Instance @data.rest()
    init: -> new Instance @data.init()

    split: (p) ->
      [l, x, r] = @data.split p
      [new Instance(l), x, new Instance(r)]

    takeUntil: (p) -> new Instance @data.takeUntil p
    dropUntil: (p) -> new Instance @data.dropUntil p
    find:      (p) -> @data.find p

    split = (data, k) ->
      [l, x, r] = data.split((m) -> m >= k)
      [l, r.after x]

    partition: (k) ->
      [l, r] = split @data, k
      [new Instance(l), new Instance(r)]

    insert: (x) ->
      [l, r] = split @data, x
      new Instance l.concat r.after x

    deleteAll: (x) ->
      [l, r] = split @data, x
      new Instance l.concat r.dropUntil (m) -> m > x

    merge = (s, t1, t2) ->
      if t2.isEmpty()
        s.concat t1
      else
        k = t2.first()
        [l, x, r] = t1.split (m) -> m > k
        recur -> merge s.concat(l).before(k), t2.rest(), r.after(x)

    merge: (other) ->
      new Instance resolve merge Tree.build(), this.data, other.data

    toString: -> @data.toString()


  Tree = new FingerTreeType OrderMeasure, SortedExtensions

  Empty = new Instance Tree.build()

  { build: -> Sequence.reduce arguments, Empty, (s, a) -> s.insert a }
)()


# --------------------------------------------------------------------
# Exports
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.FingerTreeType = FingerTreeType
exports.CountedSeq     = CountedSeq
exports.SortedSeq      = SortedSeq
