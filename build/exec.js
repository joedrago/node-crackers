// Generated by CoffeeScript 1.9.3
(function() {
  var commandPaths, exec, fs, log, path, spawnSync, which;

  fs = require('fs');

  log = require('./log');

  path = require('path');

  spawnSync = require('child_process').spawnSync;

  which = require('which');

  commandPaths = {
    composite: null,
    convert: null,
    identify: null,
    dwebp: null,
    tar: null,
    unrar: null,
    unzip: null,
    zip: null
  };

  (function() {
    var commandMissing, name;
    if (process.platform === 'win32') {
      commandPaths.composite = path.resolve(__dirname, "../wbin/composite.exe");
      commandPaths.convert = path.resolve(__dirname, "../wbin/convert.exe");
      commandPaths.identify = path.resolve(__dirname, "../wbin/identify.exe");
      commandPaths.dwebp = path.resolve(__dirname, "../wbin/dwebp.exe");
      commandPaths.tar = path.resolve(__dirname, "../wbin/tar.exe");
      commandPaths.unrar = path.resolve(__dirname, "../wbin/unrar.exe");
      commandPaths.unzip = path.resolve(__dirname, "../wbin/unzip.exe");
      commandPaths.zip = path.resolve(__dirname, "../wbin/zip.exe");
    } else {
      for (name in commandPaths) {
        try {
          commandPaths[name] = which.sync(name);
        } catch (_error) {

        }
      }
    }
    commandMissing = false;
    for (name in commandPaths) {
      path = commandPaths[name];
      if (path === null) {
        log.error("crackers requires " + name + " to be installed.");
        commandMissing = true;
      }
    }
    if (commandMissing) {
      process.exit(1);
    }
    return log.verbose("commandPaths: " + (JSON.stringify(commandPaths, null, 2)));
  })();

  exec = function(cmdName, args, workingDir) {
    var commandPath, results;
    commandPath = commandPaths[cmdName];
    if (!commandPath) {
      log.error("Attempting to run unknown external command '" + cmdName + "'");
      process.exit(1);
    }
    log.verbose("executing external command " + cmdName + " (" + commandPath + "), args [ " + args + " ], workingDir " + workingDir);
    results = spawnSync(commandPath, args, {
      cwd: workingDir
    });
    return String(results.stdout);
  };

  module.exports = exec;

  'globals: commandPaths';

}).call(this);
