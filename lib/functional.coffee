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
# Only the first call to the returned function will evaluate the given
# code; the remaining ones will return a cached result.
# --------------------------------------------------------------------

exports.suspend = (code) ->
  f = -> val = code(); (f = -> val)()
  -> f()


# --------------------------------------------------------------------
# A function to simulate tail call optimization.
# --------------------------------------------------------------------

exports.bounce = (val) -> val = val() while typeof val == 'function'; val


# --------------------------------------------------------------------
# This function simulates a local scope.
# --------------------------------------------------------------------

exports.scope = (args, f) -> f(args...)
