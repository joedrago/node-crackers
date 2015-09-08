Crackers = require './crackers'
exec = require './exec'
log = require './log'

syntax = ->
  log.syntax "Syntax: crackers [-h] [-v] [-c] [-u] directoryName"
  log.syntax "        -h,--help         This help output"
  log.syntax "        -v,--verbose      Verbose output"
  log.syntax "        -c,--cover        Force regeneration of covers"
  log.syntax "        -u,--unpack       Force reunpack of cbr/cbz files"
  process.exit(1)

main = ->
  args = require('minimist')(process.argv.slice(2), {
    boolean: ['h', 'v', 'c', 'u']
    alias:
      help: 'h'
      verbose: 'v'
      cover: 'c'
      unpack: 'u'
  })
  if args.help or args._.length != 1
    syntax()

  log.setVerbose(args.verbose)
  directoryName = args._[0]

  crackers = new Crackers
  crackers.update {
    dir: directoryName
    force:
      cover: args.cover
      unpack: args.unpack
  }

module.exports =
  main: main
