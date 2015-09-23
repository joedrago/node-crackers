// Generated by CoffeeScript 1.9.3
(function() {
  var Crackers, exec, log, main, syntax;

  Crackers = require('./crackers');

  exec = require('./exec');

  log = require('./log');

  syntax = function() {
    log.syntax("Syntax: crackers [-h]");
    log.syntax("        crackers [-v] [-c] [-u]   update   PATH           (aliases: create, generate, gen)");
    log.syntax("        crackers [-v] [-x] [-t T] organize PATH [PATH...] (aliases: rename, mv)");
    log.syntax("        crackers [-v] [-x]        cleanup  PATH [PATH...] (aliases: remove, rm, del)");
    log.syntax("");
    log.syntax("Global options:");
    log.syntax("        -h,--help         This help output");
    log.syntax("        -v,--verbose      Verbose output");
    log.syntax("");
    log.syntax("Update options:");
    log.syntax("        -c,--cover        Force regeneration of covers");
    log.syntax("        -d,--download     Show download links when cbr/cbz files are still present");
    log.syntax("        -u,--unpack       Force reunpack of cbr/cbz files");
    log.syntax("");
    log.syntax("Organize options:");
    log.syntax("        -t,--template T   Use template T when renaming. Default: {name}/{issue.3}");
    log.syntax("");
    log.syntax("Organize / Cleanup options:");
    log.syntax("        -x,--execute      Perform rename/remove (default is to simply list actions)");
    log.syntax("");
    return process.exit(1);
  };

  main = function() {
    var args, crackers, directoryName, mode, modeInput;
    args = require('minimist')(process.argv.slice(2), {
      boolean: ['h', 'v', 'c', 'u', 'x'],
      string: ['t'],
      alias: {
        help: 'h',
        verbose: 'v',
        cover: 'c',
        download: 'd',
        template: 't',
        unpack: 'u',
        execute: 'x'
      }
    });
    if (args.help || args._.length < 1) {
      syntax();
    }
    modeInput = args._.shift();
    mode = (function() {
      switch (modeInput) {
        case 'update':
        case 'create':
        case 'generate':
        case 'gen':
          return 'update';
        case 'organize':
        case 'rename':
        case 'mv':
          return 'organize';
        case 'cleanup':
        case 'remove':
        case 'rm':
        case 'del':
          return 'cleanup';
        default:
          log.syntax("crackers' first ordered argument must be a command.");
          return syntax();
      }
    })();
    log.setVerbose(args.verbose);
    crackers = new Crackers;
    if (mode === 'update') {
      if (args._.length !== 1) {
        log.syntax("update requires exactly one directory as its argument.");
        syntax();
      }
      directoryName = args._[0];
      return crackers.update({
        dir: directoryName,
        download: args.download,
        force: {
          cover: args.cover,
          unpack: args.unpack
        }
      });
    } else if (mode === 'organize') {
      if (args._.length === 0) {
        log.syntax("organize requires at least one path.");
        syntax();
      }
      return crackers.organize({
        filenames: args._,
        execute: args.execute,
        template: args.template
      });
    } else if (mode === 'cleanup') {
      if (args._.length === 0) {
        log.syntax("cleanup requires at least one path.");
        syntax();
      }
      return crackers.cleanup({
        filenames: args._,
        execute: args.execute
      });
    }
  };

  module.exports = {
    main: main
  };

}).call(this);
