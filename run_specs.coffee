require.paths.unshift('../jasmine-node/lib')

jasmine = require 'jasmine'
sys = require 'sys'

for key, val of jasmine
  this[key] = val

isVerbose = false
showColors = true
pattern = "_spec.coffee$"

process.argv[2..].forEach (arg) ->
  switch arg
    when '--color'   then showColors = true
    when '--noColor' then showColors = false
    when '--verbose' then isVerbose  = true
    else                  pattern = arg

jasmine.executeSpecsInFolder(
  process.cwd() + '/spec',
  ((runner, log) -> process.exit(runner.results().failedCount)),
  isVerbose,
  showColors,
  pattern)
