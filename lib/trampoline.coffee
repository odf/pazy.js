# --------------------------------------------------------------------
# A pair of functions that simulate tail call optimization.
#
# Example:
#
#     factorial = (n) ->
#       fac = (n, p) -> if n then recur -> fac(n-1, p * n) else p
#       resolve fac(n, 1)
#
#
# Copyright (c) 2010 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}

exports.recur   = (code) -> { recur__: code }
exports.resolve = (val) -> val = val.recur__() while val?.recur__; val
