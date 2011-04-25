# --------------------------------------------------------------------
# A union-find data structure.
#
# Copyright (c) 2011 Olaf Delgado-Friedrichs (odf@github.com)
# --------------------------------------------------------------------

if typeof(require) != 'undefined'
  require.paths.unshift __dirname
  { recur, resolve } = require('functional')
  { HashMap }        = require('indexed')
else
  { recur, resolve, HashMap } = this.pazy


class Partition
  constructor: ->
    @rank   = new HashMap()
    @parent = new HashMap()

  make = (rank, parent) ->
    p = new Partition()
    p.rank   = rank
    p.parent = parent
    p

  find: (x) ->
    if not @parent.get(x)?
      @parent = @parent.plus [x, x]
      @rank = @rank.plus [x, 0]
      x
    else
      seek = (y) =>
        z = @parent.get y
        if z == y then z else recur -> seek z
      root = resolve seek x

      flatten = (y) =>
        z = @parent.get y
        @parent = @parent.plus [y, root]
        if z != y then recur -> flatten z
      resolve flatten x

      root

  union: (x, y) ->
    xRoot = @find x
    yRoot = @find y

    if xRoot == yRoot
      this
    else
      xRank = @rank.get xRoot
      yRank = @rank.get yRoot

      if xRank < yRank
        make @rank, @parent.plus [xRoot, yRoot]
      else if xRank > yRank
        make @rank, @parent.plus [yRoot, xRoot]
      else
        make @rank.plus([xRoot, xRank + 1]), @parent.plus [yRoot, xRoot]


# --------------------------------------------------------------------
# Exporting.
# --------------------------------------------------------------------

exports ?= this.pazy ?= {}
exports.Partition = Partition
