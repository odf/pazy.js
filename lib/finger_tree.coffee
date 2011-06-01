# --------------------------------------------------------------------
# A finger tree implementation.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


reducel: (op) -> (z, x) -> x.reducel(z, op)
reducer: (op) -> (x, z) -> x.reducer(op, z)


# A node.
class Node2
  constructor: -> [@a, @b] = arguments
  reducel: (z, op) -> op(op(z, @a), @b)
  reducer: (op, z) -> op(@a, op(@b, z))

class Node3
  constructor: -> [@a, @b, @c] = arguments
  reducel: (z, op) -> op(op(op(z, @a), @b), @c)
  reducer: (op, z) -> op(@a, op(@b, op(@c, z)))

make_node = (args...) ->
  type = switch args.length
    when 2 then Digit2
    when 3 then Digit3
    else
      raise new Error "Illegal number of arguments: #{args.length}"

  new type args...


# A digit in a finger tree.
class Digit1
  constructor: -> [@a] = arguments
  reducel: (z, op) -> op(z, @a)
  reducer: (op, z) -> op(@a, z)

class Digit2
  constructor: -> [@a, @b] = arguments
  reducel: (z, op) -> op(op(z, @a), @b)
  reducer: (op, z) -> op(@a, op(@b, z))

class Digit3
  constructor: -> [@a, @b, @c] = arguments
  reducel: (z, op) -> op(op(op(z, @a), @b), @c)
  reducer: (op, z) -> op(@a, op(@b, op(@c, z)))

class Digit4
  constructor: -> [@a, @b, @c, @d] = arguments
  reducel: (z, op) -> op(op(op(op(z, @a), @b), @c), @d)
  reducer: (op, z) -> op(@a, op(@b, op(@c, op(@d, z))))

make_digit = (args...) ->
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
  reducel: (z, op) -> z
  reducer: (op, z) -> z
}


# A finger tree with a single element.
class Single
  constructor: (a) -> @a = a

  reducel: (z, op) -> op z, @a
  reducer: (op, z) -> op @a, z


# A deep finger tree.
class Deep
  constructor: (left, middle, right) ->
    @l = left
    @m = middle
    @r = right

  reducel: (z, op0) ->
    op1 = reducel op0
    op2 = reducel op1
    op1(op2(op1(z, @l), @m), @r)

  reducer: (op0, z) ->
    op1 = reducer op0
    op2 = reducer op1
    op1(@l, op2(@m, op1(@r, z)))
