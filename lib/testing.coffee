# Some function to support testing.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# Displays a line of code alongside the type and value of its output.
#
# For example, the line
#
#   show -> 1 * 2 * 3
#
# or, in Javascript
#
#   show( function () { return 1 * 2 * 3 } )
#
# produces this output:
#
#   1 * 2 * 3                           -> Number 6
#
# Assignments can be used, but in Coffeescript, the variables need to be
# present in the enclosing scope first. So, one can write
#
#   a = 0
#   show -> a = 1 * 2 * 3
#   show -> Math.sqrt a
#
# and get
#
#   a = 1 * 2 * 3                       -> Number 6
#   Math.sqrt(a)                        -> Number 2.449489742783178
#
# Unfortunately, the latter does not work in the Coffeescript console.

show = (code, catchExceptions = true) ->
  s = code.toString().replace /^function\s*\(\)\s*{\s*return\s*(.*);?\s*}/, "$1"
  source = s + "                                    "[s.length..]

  result =
    try
      res = code()
      type = if res?.constructor?
        res.constructor.name
      else if res?
        typeof res
      if type? then "-> #{type} #{res}" else "-> #{res}"
    catch ex
      if catchExceptions
        "!! #{ex}"
      else
        throw ex

  console.log source + result

# ----

# Exporting.

exports ?= pazy ?= {}
exports.show = show
