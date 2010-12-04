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

recur = (code) -> { _recur: code }

resolve = (val) -> val = val._recur() while val?._recur; val


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

if typeof(exports) == 'undefined'
  this.pazy = {} if typeof this.pazy == 'undefined'
  this.pazy.recur = recur
  this.pazy.resolve = resolve
else
  exports.recur = recur
  exports.resolve = resolve
