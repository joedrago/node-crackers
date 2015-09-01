util = require 'util'
{spawn} = require 'child_process'

coffeeName = 'coffee'
if process.platform == 'win32'
  coffeeName += '.cmd'

task 'build', 'build JS bundle', (options) ->
  coffee = spawn coffeeName, ['-c', '-o', 'js', 'src']
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
    process.exit(-1)
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    util.log "Compilation finished."
    callback?() if code is 0
