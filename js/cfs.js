// Generated by CoffeeScript 1.9.3
(function() {
  var cfs, constants, fs, log, path, wrench;

  constants = require('./constants');

  fs = require('fs');

  path = require('path');

  log = require('./log');

  wrench = require('wrench');

  cfs = {};

  cfs.join = function() {
    var result;
    result = path.join.apply(null, arguments);
    if (arguments.length > 0 && arguments[0] === '') {
      result = "/" + result;
    }
    return result;
  };

  cfs.dirExists = function(dir) {
    var stats;
    if (!fs.existsSync(dir)) {
      return false;
    }
    stats = fs.statSync(dir);
    if (stats.isDirectory()) {
      return true;
    }
    return false;
  };

  cfs.fileExists = function(file) {
    var stats;
    if (!fs.existsSync(file)) {
      return false;
    }
    stats = fs.statSync(file);
    if (stats.isFile()) {
      return true;
    }
    return false;
  };

  cfs.findParentContainingFilename = function(startDir, filename) {
    var dirPieces, found, testPath, testPieces;
    startDir = path.resolve('.', startDir);
    dirPieces = startDir.split(path.sep);
    while (true) {
      if (!dirPieces.length) {
        return false;
      }
      testPieces = dirPieces.slice();
      testPieces.push(filename);
      testPath = cfs.join.apply(null, testPieces);
      found = cfs.fileExists(testPath);
      if (found) {
        return cfs.join.apply(null, dirPieces);
      }
      dirPieces.pop();
    }
    return false;
  };

  cfs.listDir = function(dir) {
    return wrench.readdirSyncRecursive(dir);
  };

  cfs.listImages = function(dir) {
    var file, images, list;
    list = wrench.readdirSyncRecursive(dir);
    images = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = list.length; i < len; i++) {
        file = list[i];
        if (file.match(/\.(png|jpg|jpeg)$/i)) {
          results.push(path.resolve(dir, file));
        }
      }
      return results;
    })();
    return images.sort();
  };

  cfs.gatherIndex = function(dir) {
    var file, fileList, i, indexList, len, metadata, resolvedPath;
    indexList = [];
    fileList = fs.readdirSync(dir).sort();
    for (i = 0, len = fileList.length; i < len; i++) {
      file = fileList[i];
      resolvedPath = path.resolve(dir, file);
      metadata = cfs.readMetadata(resolvedPath);
      if (!metadata) {
        continue;
      }
      indexList.push({
        path: file,
        type: metadata.type,
        count: metadata.count,
        cover: metadata.cover
      });
    }
    indexList.sort(function(a, b) {
      if (a.type === b.type) {
        if (a.path === b.path) {
          return 0;
        }
        if (a.path > b.path) {
          return 1;
        }
        return -1;
      }
      if (a.type > b.type) {
        return 1;
      }
      return -1;
    });
    return indexList;
  };

  cfs.readMetadata = function(dir) {
    var metaFilename, metadata, rawText;
    metaFilename = cfs.join(dir, constants.META_FILENAME);
    if (!fs.existsSync(metaFilename)) {
      return false;
    }
    rawText = fs.readFileSync(metaFilename);
    if (!rawText) {
      return false;
    }
    try {
      metadata = JSON.parse(rawText);
    } catch (_error) {
      metadata = false;
    }
    return metadata;
  };

  cfs.writeMetadata = function(dir, metadata) {
    var json;
    this.metaFilename = cfs.join(dir, constants.META_FILENAME);
    json = JSON.stringify(metadata, null, 2);
    log.verbose("writeMetadata (" + dir + "): " + metadata);
    return fs.writeFileSync(this.metaFilename, json);
  };

  cfs.prepareDir = function(dir) {
    var stats;
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir);
    }
    if (!fs.existsSync(dir)) {
      log.error("Cannot create directory " + dir + ", mkdir failed");
      return false;
    }
    stats = fs.statSync(dir);
    if (!stats.isDirectory()) {
      log.error("Cannot create directory " + dir + ", file exists (not a dir)");
      return false;
    }
    return true;
  };

  cfs.prepareComicDir = function(dir) {
    if (!cfs.prepareDir(dir)) {
      return false;
    }
    log.verbose("Comic directory prepared: " + dir);
    return true;
  };

  cfs.cleanupDir = function(dir) {
    if (fs.existsSync(dir)) {
      log.verbose("Cleaning up " + dir);
      wrench.rmdirSyncRecursive(dir, true);
    }
  };

  cfs.newer = function(amINewer, thanThisFile) {
    var amINewerStats, thanThisFileStats;
    if (!fs.existsSync(amINewer)) {
      return true;
    }
    if (!fs.existsSync(thanThisFile)) {
      return true;
    }
    amINewerStats = fs.statSync(amINewer);
    thanThisFileStats = fs.statSync(thanThisFile);
    return amINewerStats.mtime > thanThisFile.mtime;
  };

  module.exports = cfs;

}).call(this);
