# --------------------------------------------------------------------
# Sequence methods that require indexed collections.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Sequence } = require('sequence')
  { HashSet }  = require('indexed')
else
  { seq, HashSet } = this.pazy

Sequence.method 'uniq', (s, seen = new HashSet()) ->
  if s
    x = s.first()
    if seen.contains x
      @uniq__ s.rest(), seen
    else
      Sequence.conj x, => @uniq__ s.rest(), seen.plus x
  else
    null
