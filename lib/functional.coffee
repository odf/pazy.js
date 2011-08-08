# --------------------------------------------------------------------
# Various useful short functions that support a functional programming
# style.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
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
# A function to simulate tail call optimization.
# --------------------------------------------------------------------

exports.trampoline = (val) -> val = val() while typeof val == 'function'; val


# --------------------------------------------------------------------
# This function simulates a local scope.
# --------------------------------------------------------------------

exports.scope = (args, f) -> f(args...)
