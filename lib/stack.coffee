# --------------------------------------------------------------------
# A simple stack implemented via a Sequence.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Sequence } = require('sequence')
else
  { Sequence } = this.pazy


class Stack
  constructor: (s) -> @seq = s

  push: (x) -> new Stack Sequence.conj x, => @seq

  first: -> @seq?.first()

  rest: -> if @seq then new Stack @seq.rest()


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Stack = Stack
