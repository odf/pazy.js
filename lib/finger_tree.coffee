# --------------------------------------------------------------------
# A finger tree implementation.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


reduceLeft  = (op) -> (z, x) -> x.reduceLeft(z, op)
reduceRight = (op) -> (x, z) -> x.reduceRight(op, z)


# A node.
class Node2
  constructor: -> [@a, @b] = arguments
  reduceLeft:  (z, op) -> op(op(z, @a), @b)
  reduceRight: (op, z) -> op(@a, op(@b, z))

class Node3
  constructor: -> [@a, @b, @c] = arguments
  reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
  reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))

makeNode = (args...) ->
  type = switch args.length
    when 2 then Digit2
    when 3 then Digit3
    else
      raise new Error "Illegal number of arguments: #{args.length}"

  new type args...


# A digit in a finger tree.
class Digit1
  constructor: -> [@a] = arguments
  reduceLeft:  (z, op) -> op(z, @a)
  reduceRight: (op, z) -> op(@a, z)

class Digit2
  constructor: -> [@a, @b] = arguments
  reduceLeft:  (z, op) -> op(op(z, @a), @b)
  reduceRight: (op, z) -> op(@a, op(@b, z))

class Digit3
  constructor: -> [@a, @b, @c] = arguments
  reduceLeft:  (z, op) -> op(op(op(z, @a), @b), @c)
  reduceRight: (op, z) -> op(@a, op(@b, op(@c, z)))

class Digit4
  constructor: -> [@a, @b, @c, @d] = arguments
  reduceLeft:  (z, op) -> op(op(op(op(z, @a), @b), @c), @d)
  reduceRight: (op, z) -> op(@a, op(@b, op(@c, op(@d, z))))

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
}


# A finger tree with a single element.
class Single
  constructor: (a) -> @a = a

  reduceLeft:  (z, op) -> op z, @a
  reduceRight: (op, z) -> op @a, z


# A deep finger tree.
class Deep
  constructor: (left, middle, right) ->
    @l = left
    @m = middle
    @r = right

  reduceLeft: (z, op0) ->
    op1 = reduceLeft op0
    op2 = reduceLeft op1
    op1(op2(op1(z, @l), @m), @r)

  reduceRight: (op0, z) ->
    op1 = reduceRight op0
    op2 = reduceRight op1
    op1(@l, op2(@m, op1(@r, z)))


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.reduceLeft  = reduceLeft
exports.reduceRight = reduceRight
exports.makeDigit   = makeDigit
exports.makeNode    = makeNode
exports.Empty  = Empty
exports.Single = Single
exports.Deep   = Deep
