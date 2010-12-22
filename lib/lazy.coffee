# --------------------------------------------------------------------
# An implementation of the suspend/force paradigm of lazy evaluation
# via simple function memoization.
#
# Usage example:
#   f = suspend(-> 2 * 3)
#   f(); f(); f()
#
# Only the first call to f will evaluate the expression 2 * 3; the
# remaining ones will return a cached result.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------


exports ?= this.pazy ?= {}

exports.suspend = (code) ->
  val = null
  ->
    [val, code] = [code(); null] if code
    val
