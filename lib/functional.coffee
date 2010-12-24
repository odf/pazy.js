# --------------------------------------------------------------------
# Various useful short functions that support a functional programming
# style.
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

# --------------------------------------------------------------------
# An implementation of the suspend/force paradigm of lazy evaluation
# via simple function memoization.
#
# Only the first call to f will evaluate the given code; the remaining
# ones will return a cached result.
# --------------------------------------------------------------------

exports.suspend = (code) ->
  val = null
  ->
    if code
      val = code()
      code = null
    val


# --------------------------------------------------------------------
# A pair of functions that simulate tail call optimization.
# --------------------------------------------------------------------

exports.recur   = (code) -> { recur__: code }
exports.resolve = (val) -> val = val.recur__() while val?.recur__; val


# --------------------------------------------------------------------
# This function simulates a local scope.
# --------------------------------------------------------------------

exports.scope = (args, f) -> f(args...)
