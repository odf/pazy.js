# Cakefile for pazy.js
#
# (based on https://github.com/krismolendyke/InstantJasmineCoffee)


fs     = require 'fs'
{exec} = require 'child_process'
util   = require 'util'
uglify = require 'uglify-js'

prodSrcCoffeeDir     = 'lib'
prodTargetJsDir      = '.'

prodTargetFileName   = 'pazy'
prodTargetCoffeeFile = "#{prodSrcCoffeeDir}/#{prodTargetFileName}.coffee"
prodTargetJsFile     = "#{prodTargetJsDir}/#{prodTargetFileName}.js"
prodTargetJsMinFile  = "#{prodTargetJsDir}/#{prodTargetFileName}.min.js"

prodCoffeeOpts = "--output #{prodTargetJsDir} --compile #{prodTargetCoffeeFile}"

prodCoffeeFiles = [
  'core_extensions'
  'functional'
  'sequence'
  'indexed'
  'sequence_extras'
  'finger_tree'
  'partition'
  'stack'
  'queue'
  'number'
]

task 'watch', 'Watch prod source files and build changes', ->
    invoke 'build'
    util.log "Watching for changes in #{prodSrcCoffeeDir}"

    for file in prodCoffeeFiles then do (file) ->
        fs.watchFile "#{prodSrcCoffeeDir}/#{file}.coffee", (curr, prev) ->
            if +curr.mtime isnt +prev.mtime
                util.log "Saw change in #{prodSrcCoffeeDir}/#{file}.coffee"
                invoke 'build'

task 'build', 'Build a single JavaScript file from prod files', ->
    util.log "Building #{prodTargetJsFile}"
    appContents = new Array remaining = prodCoffeeFiles.length
    util.log "Appending #{prodCoffeeFiles.length} files to #{prodTargetCoffeeFile}"

    for file, index in prodCoffeeFiles then do (file, index) ->
        fs.readFile "#{prodSrcCoffeeDir}/#{file}.coffee"
                  , 'utf8'
                  , (err, fileContents) ->
            handleError(err) if err

            appContents[index] = fileContents
            util.log "[#{index + 1}] #{file}.coffee"
            process() if --remaining is 0

    process = ->
        fs.writeFile prodTargetCoffeeFile
                   , appContents.join('\n\n')
                   , 'utf8'
                   , (err) ->
            handleError(err) if err

            exec "coffee #{prodCoffeeOpts}", (err, stdout, stderr) ->
                handleError(err) if err
                message = "Compiled #{prodTargetJsFile}"
                util.log message
                displayNotification message
                fs.unlink prodTargetCoffeeFile, (err) -> handleError(err) if err
                invoke 'uglify'

task 'uglify', 'Minify and obfuscate', ->
    result = uglify.minify(prodTargetJsFile)
    fs.writeFile prodTargetJsMinFile, result.code

    message = "Uglified #{prodTargetJsMinFile}"
    util.log message
    displayNotification message

coffee = (options = "", file) ->
    util.log "Compiling #{file}"
    exec "coffee #{options} --compile #{file}", (err, stdout, stderr) ->
        handleError(err) if err
        displayNotification "Compiled #{file}"

handleError = (error) ->
    util.log error
    displayNotification error

displayNotification = (message = '') ->
    options = {
        title: 'CoffeeScript'
        image: 'lib/CoffeeScript.png'
    }
    try require('./node_modules/growl').notify message, options
