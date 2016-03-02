browserify = require 'browserify'
coffeeify = require 'coffeeify'
fs = require 'fs'
{spawn} = require 'child_process'
util = require 'util'

coffeeName = 'coffee'
if process.platform == 'win32'
  coffeeName += '.cmd'

buildUI = (callback) ->
  # equal of command line $ "browserify --debug -t coffeeify ./src/main.coffee > bundle.js "
  b = browserify {
    # debug: true
    transform: coffeeify
    extensions: ['.coffee']
  }
  b.add './src/ui/main.coffee'
  b.bundle (err, result) ->
    if not err
      fs.writeFile "build/templates/ui.js", result, (err) ->
        if not err
          util.log "UI compilation finished."
          callback?()
        else
          util.log "UI bundle write failed: " + err
    else
      util.log "UI compilation failed: " + err

buildTool = (callback) ->
  coffee = spawn coffeeName, ['-c', '-o', 'build', 'src/tool']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
    process.exit(-1)
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    util.log "Tool compilation finished."
    callback?() if code is 0

task 'build', 'build JS bundle', (options) ->
  buildTool ->
    buildUI ->
