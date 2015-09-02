Crackers = require './crackers'
exec = require './exec'
log = require './log'

syntax = ->
  log.syntax "Syntax: crackers [-h] [-v] directoryName"
  log.syntax "        -h,--help         This help output"
  log.syntax "        -v,--verbose      Verbose output"
  process.exit(1)

main = ->
  args = require('minimist')(process.argv.slice(2), {
    boolean: ['h', 'v']
    alias:
      help: 'h'
      verbose: 'v'
  })
  if args.help or args._.length != 1
    syntax()

  log.setVerbose(args.verbose)
  directoryName = args._[0]

  crackers = new Crackers
  crackers.update {
    dir: directoryName
  }

module.exports =
  main: main
