fs = require 'fs'
log = require './log'
path = require 'path'
{spawnSync} = require 'child_process'
which = require 'which'

commandPaths =
  unzip: null
  unrar: null
  convert: null
  composite: null

if process.platform == 'win32'
  commandPaths.unzip = path.resolve(__dirname, "../wbin/unzip.exe")
  commandPaths.unrar = path.resolve(__dirname, "../wbin/unrar.exe")
  commandPaths.convert = path.resolve(__dirname, "../wbin/convert.exe")
  commandPaths.composite = path.resolve(__dirname, "../wbin/composite.exe")
else
  for name of commandPaths
    try
      commandPaths[name] = which.sync(name)
    catch

commandMissing = false
for name, path of commandPaths
  if path == null
    log.error "crackers requires #{name} to be installed."
    commandMissing = true

if commandMissing
  process.exit(1)

log.verbose "commandPaths: #{JSON.stringify(commandPaths, null, 2)}"

module.exports = (cmdName, args, workingDir) ->
  commandPath = commandPaths[cmdName]
  if not commandPath
    log.error "Attempting to run unknown external command '#{cmdName}'"
    process.exit(1)

  log.verbose "executing external command #{cmdName} (#{commandPath}), args [ #{args} ], workingDir #{workingDir}"
  spawnSync(commandPath, args, {
    cwd: workingDir
    stdio: 'ignore'
  })
  return