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


class SizeMeasurement
  constructor: (@v) ->

  plus: (other) -> new SizeMeasurement this.v + other.v

  @empty: 0
  @norm: (x) -> new SizeMeasurement 1


class FingerTreeType
  constructor: (measurement = SizeMeasurement) ->
    T = this
    norm = (x) ->
      switch x.constructor
        when T.Node2, T.Node3 then x.norm()
        else measurement.norm(x)

    # A node.
    @Node2 = class
      constructor: ->
        [@a, @b] = arguments
        @v = norm(@a).plus norm(@b)

      reduceLeft:  (z, op) -> op(op(z, @a), @b)
      reduceRight: (op, z) -> op(@a, op(@b, z))
      asDigit:  -> new T.Digit2 @a, @b
      norm: -> @v

    @Node3 = class
      constructor: ->
        [@a, @b, @c] = arguments
        @v = norm(@a).plus(norm(@b)).plus norm(@c)

      reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
      reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))
      asDigit:  -> new T.Digit3 @a, @b, @c
      norm: -> @v

    makeNode = (args...) ->
      type = switch args.length
        when 2 then T.Node2
        when 3 then T.Node3
        else
          raise new Error "Illegal number of arguments: #{args.length}"

      new type args...


    # A digit in a finger tree.
    @Digit1 = class
      constructor: -> [@a] = arguments

      reduceLeft:  (z, op) -> op(z, @a)
      reduceRight: (op, z) -> op(@a, z)

      after:  (x) -> new T.Digit2 x, @a
      before: (x) -> new T.Digit2 @a, x

      first: -> @a
      last:  -> @a

      rest: -> T.Empty
      init: -> T.Empty

      norm: -> norm(@a)

    @Digit2 = class
      constructor: -> [@a, @b] = arguments

      reduceLeft:  (z, op) -> op(op(z, @a), @b)
      reduceRight: (op, z) -> op(@a, op(@b, z))

      after:  (x) -> new T.Digit3 x, @a, @b
      before: (x) -> new T.Digit3 @a, @b, x

      first: -> @a
      last:  -> @b

      rest: -> new T.Digit1 @b
      init: -> new T.Digit1 @a

      asNode: -> new T.Node2 @a, @b

      norm: -> norm(@a).plus(norm(@b))

    @Digit3 = class
      constructor: -> [@a, @b, @c] = arguments

      reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
      reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))

      after:  (x) -> new T.Digit4 x, @a, @b, @c
      before: (x) -> new T.Digit4 @a, @b, @c, x

      first: -> @a
      last:  -> @c

      rest: -> new T.Digit2 @b, @c
      init: -> new T.Digit2 @a, @b

      asNode: -> new T.Node3 @a, @b, @c

      norm: -> norm(@a).plus(norm(@b)).plus(norm(@c))

    @Digit4 = class
      constructor: -> [@a, @b, @c, @d] = arguments

      reduceLeft:  (z, op) -> op(op(op(op(z, @a), @b), @c), @d)
      reduceRight: (op, z) -> op(@a, op(@b, op(@c, op(@d, z))))

      first: -> @a
      last:  -> @d

      rest: -> new T.Digit3 @b, @c, @d
      init: -> new T.Digit3 @a, @b, @c

      norm: -> norm(@a).plus(norm(@b)).plus(norm(@c)).plus(norm(@d))

    makeDigit = (args...) ->
      type = switch args.length
        when 1 then T.Digit1
        when 2 then T.Digit2
        when 3 then T.Digit3
        when 4 then T.Digit4
        else
          raise new Error "Illegal number of arguments: #{args.length}"

      new type args...


    # An empty finger tree.
    @Empty = {
      reduceLeft:  (z, op) -> z
      reduceRight: (op, z) -> z

      after:  (a) -> new T.Single a
      before: (a) -> new T.Single a

      first: ->
      last:  ->

      rest: ->
      init: ->

      concat: (t) -> t

      norm: -> measurement.empty
    }


    # A finger tree with a single element.
    @Single = class
      constructor: (a) -> @a = a

      reduceLeft:  (z, op) -> op z, @a
      reduceRight: (op, z) -> op @a, z

      after:  (x) -> new T.Deep makeDigit(x), (-> T.Empty), makeDigit(@a)
      before: (x) -> new T.Deep makeDigit(@a), (-> T.Empty), makeDigit(x)

      first: -> @a
      last:  -> @a

      rest: -> T.Empty
      init: -> T.Empty

      concat: (t) -> t.after @a

      norm: -> norm @a


    # A deep finger tree.
    @Deep = class
      reduceLeft  = (op) -> (z, x) -> x.reduceLeft(z, op)
      reduceRight = (op) -> (x, z) -> x.reduceRight(op, z)

      asTree = (s) -> s.reduceLeft T.Empty, (a, b) -> a.before b
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
        if @l.constructor == T.Digit4
          { a, b, c, d } = @l
          new T.Deep makeDigit(x, a), (=> @m().after(makeNode(b, c, d))), @r
        else
          new T.Deep @l.after(x), @m, @r

      before: (x) ->
        if @r.constructor == T.Digit4
          { a, b, c, d } = @r
          new T.Deep @l, (=> @m().before(makeNode(a, b, c))), makeDigit(d, x)
        else
          new T.Deep @l, @m, @r.before(x)

      first: -> @l.first()
      last:  -> @r.last()

      rest: ->
        if  @l.rest() == T.Empty
          if @m() == T.Empty
            asTree @r
          else
            new T.Deep @m().first().asDigit(), (=> @m().rest()), @r
        else
          new T.Deep @l.rest(), @m, @r

      init: ->
        if  @r.init() == T.Empty
          if @m() == T.Empty
            asTree @l
          else
            new T.Deep @l, (=> @m().init()), @m().last().asDigit()
        else
          new T.Deep @l, @m, @r.init()

      nodes = (n, s) ->
        if n == 0
          null
        else if n == 2 or n % 3 == 1
          Sequence.conj new T.Node2(s.take(3).into([])...),
            -> nodes n-2, s.drop 2
        else if n >= 3
          Sequence.conj new T.Node3(s.take(3).into([])...),
            -> nodes n-3, s.drop 3
        else
          raise new Error "this should not happen"

      app3 = (tLeft, list, tRight) ->
        if tLeft == T.Empty
          Sequence.reduce Sequence.reverse(list), tRight, (t, x) -> t.after x
        else if tRight == T.Empty
          Sequence.reduce list, tLeft, (t, x) -> t.before x
        else if tLeft.constructor == T.Single
          app3(T.Empty, list, tRight).after tLeft.a
        else if tRight.constructor == T.Single
          app3(tLeft, list, T.Empty).before tRight.a
        else
          tmp = Sequence.flatten [asSeq(tLeft.r), list,  asSeq(tRight.l)]
          s = nodes tmp.size(), tmp
          new T.Deep tLeft.l, (-> app3 tLeft.m(), s, tRight.m()), tRight.r

      concat: (t) -> app3 this, null, t


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.Empty = new FingerTreeType().Empty
