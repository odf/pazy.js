jasmine = require '../jasmine-node/lib/jasmine'
sys = require 'sys'

for key, val of jasmine
  this[key] = val

isVerbose = false
showColors = true

process.argv.forEach (arg) ->
  switch arg
    when '--color'   then showColors = true
    when '--noColor' then showColors = false
    when '--verbose' then isVerbose  = true

jasmine.executeSpecsInFolder(
  process.cwd() + '/spec',
  ((runner, log) -> process.exit(runner.results().failedCount)),
  isVerbose,
  showColors,
  "_spec.coffee$")
