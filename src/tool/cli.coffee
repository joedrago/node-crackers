Crackers = require './Crackers'
exec = require './exec'
log = require './log'

main = ->
  syntax = ->
    log.syntax "Syntax: crackers [-h]"
    log.syntax "        crackers [-v] [-c] [-u]          update   PATH           (aliases: create, generate, gen)"
    log.syntax "        crackers [-v] [-x] [-t T] [-s N] organize PATH [PATH...] (aliases: rename, mv)"
    log.syntax "        crackers [-v] [-x]               cleanup  PATH [PATH...] (aliases: remove, rm, del)"
    log.syntax "        crackers [-v] [-x] [-t T] [-s N] merge    PATH [PATH...]"
    log.syntax "        crackers [-v]                    archive  PATH [PATH...]"
    log.syntax ""
    log.syntax "Global options:"
    log.syntax "        -h,--help         This help output"
    log.syntax "        -v,--verbose      Verbose output"
    log.syntax ""
    log.syntax "Update options:"
    log.syntax "        -c,--cover        Force regeneration of covers"
    log.syntax "        -d,--download     Show download links when cbr/cbt/cbz files are still present"
    log.syntax "        -u,--unpack       Force reunpack of cbr/cbt/cbz files"
    log.syntax ""
    log.syntax "Organize options:"
    log.syntax "        -s,--skip N       Skip N sets of digits when looking for the issue (default: 0)"
    log.syntax "        -t,--template T   Use template T when renaming. Default: {name}/{issue.3}"
    log.syntax ""
    log.syntax "Merge options:"
    log.syntax "        -m,--merge DIR    merge destination (defaults to current directory)"
    log.syntax ""
    log.syntax "Organize / Cleanup / Merge options:"
    log.syntax "        -x,--execute      Perform rename/remove (default is to simply list actions)"
    log.syntax ""
    log.syntax "Archive options:"
    log.syntax "        -f,--force        Force re-archive"
    log.syntax ""
    process.exit(1)

  args = require('minimist')(process.argv.slice(2), {
    boolean: ['h', 'v', 'c', 'u', 'x', 'f']
    string: ['t','m','s']
    alias:
      help: 'h'
      verbose: 'v'
      cover: 'c'
      download: 'd'
      force: 'f'
      merge: 'm'
      skip: 's'
      template: 't'
      unpack: 'u'
      execute: 'x'
  })
  if args.help or args._.length < 1
    syntax()

  modeInput = args._.shift()
  mode = switch modeInput
    when 'update', 'create', 'generate', 'gen'
      'update'
    when 'organize', 'rename', 'mv'
      'organize'
    when 'cleanup', 'remove', 'rm', 'del'
      'cleanup'
    when 'merge'
      'merge'
    when 'archive'
      'archive'
    else
      log.syntax "crackers' first ordered argument must be a command."
      syntax()

  log.setVerbose(args.verbose)
  crackers = new Crackers

  if mode == 'update'
    if args._.length != 1
      log.syntax "update requires exactly one directory as its argument."
      syntax()
    directoryName = args._[0]
    crackers.update {
      dir: directoryName
      download: args.download
      force:
        cover: args.cover
        unpack: args.unpack
    }

  else if mode == 'organize'
    if args._.length == 0
      log.syntax "organize requires at least one path."
      syntax()
    crackers.organize {
      filenames: args._
      execute: args.execute
      skip: parseInt(args.skip)
      template: args.template
    }

  else if mode == 'cleanup'
    if args._.length == 0
      log.syntax "cleanup requires at least one path."
      syntax()
    crackers.cleanup {
      filenames: args._
      execute: args.execute
    }

  else if mode == 'merge'
    if args._.length == 0
      log.syntax "merge requires at least one path."
      syntax()
    dst = '.'
    if args.merge
      dst = args.merge
    crackers.organize {
      filenames: args._
      execute: args.execute
      template: args.template
      skip: parseInt(args.skip)
      dst: dst
    }

  else if mode == 'archive'
    if args._.length == 0
      log.syntax "archive requires at least one path inside of a crackers root."
      syntax()
    crackers.archive {
      filenames: args._
      force: args.force
    }

module.exports = main
