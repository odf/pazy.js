# --------------------------------------------------------------------
# Sequence methods that require indexed collections.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { Sequence} = require('sequence')
  { HashSet } = require('indexed')
else
  { Sequence, HashSet } = this.pazy

Sequence.method 'uniq', (seq, seen = new HashSet()) ->
  if @empty__ seq
    null
  else
    x = seq.first()
    if seen.contains x
      @uniq__ seq.rest(), seen
    else
      Sequence.conj x, => @uniq__ seq.rest(), seen.plus x
