# --------------------------------------------------------------------
# A simple stack implemented via a sequence.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { seq } = require('sequence')
else
  { seq } = this.pazy


class Stack
  constructor: (@s) ->

  push: (x) -> new Stack seq.conj x, => @s

  first: -> @s?.first()

  rest: -> new Stack @s?.rest()

  toSeq: -> @s


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Stack = Stack
