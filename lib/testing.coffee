# Some function to support testing.
#
# _Copyright (c) 2011 Olaf Delgado-Friedrichs_

# ----

# Returns the inner code of a 'one-line' function as a string.

codeToString = (code) ->
  code.toString().replace(/^function\s*\(\)\s*{\s*return\s*/, '')
    .replace(/;*\s*}\s*$/, '')

# Returns the name of the constructor for an object or the result of `typeof`
# if there is none (as is the case for `null` or `undefined`).

classof = (x) -> if x?.constructor? then x.constructor.name else typeof x

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

blanks = "                                   "

show = (code, catchExceptions = true) ->
  s = codeToString code
  source = if s.length > blanks.length + 1
    "#{s}\n#{blanks}"
  else
    s + blanks[s.length..]

  result =
    try
      res = code()
      "-> #{classof res} #{res}"
    catch ex
      if catchExceptions
        "!! #{ex.toString().replace /\n/, "\n#{blanks} !!   "}"
      else
        throw ex

  console.log "#{source} #{result}"

# ----

# Exporting.

exports = module?.exports or this.pazy ?= {}
exports.codeToString = codeToString
exports.classof      = classof
exports.show         = show
