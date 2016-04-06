// Generated by CoffeeScript 1.9.3
(function() {
  var ComicGenerator, Crackers, IndexGenerator, Unpacker, cfs, constants, exec, fs, log, path, wrench;

  cfs = require('./cfs');

  constants = require('./constants');

  exec = require('./exec');

  fs = require('fs');

  log = require('./log');

  path = require('path');

  wrench = require('wrench');

  ComicGenerator = require('./ComicGenerator');

  IndexGenerator = require('./IndexGenerator');

  Unpacker = require('./Unpacker');

  Crackers = (function() {
    function Crackers() {}

    Crackers.prototype.error = function(text) {
      log.error(text);
      return false;
    };

    Crackers.prototype.update = function(args) {
      var comicDir, comicGenerator, comicName, file, filesToUnpack, i, imageDir, imageDirPieces, imageDirs, indexDir, indexDirSeen, indexDirs, indexGenerator, j, k, l, len, len1, len2, len3, m, nextDir, nextParent, nextParsed, parent, parsed, prevDir, unpackDir, unpackFile;
      this.force = args.force;
      this.download = args.download;
      this.updateDir = path.resolve('.', args.dir);
      if (!cfs.dirExists(this.updateDir)) {
        return this.error("'" + this.updateDir + "' is not an existing directory.");
      }
      log.verbose("updateDir  : " + this.updateDir);
      this.rootDir = cfs.findParentContainingFilename(this.updateDir, constants.ROOT_FILENAME);
      if (!this.rootDir) {
        this.rootDir = this.updateDir;
        log.warning("crackers root not found (" + constants.ROOT_FILENAME + " not detected in parents).");
      }
      log.verbose("rootDir    : " + this.rootDir);
      this.archivesDir = path.join(this.rootDir, constants.ARCHIVES_DIR);
      log.verbose("archivesDir: " + this.archivesDir);
      cfs.touchRoot(this.rootDir);
      cfs.prepareDir(this.archivesDir);
      filesToUnpack = (function() {
        var j, len, ref, results;
        ref = cfs.listDir(this.updateDir);
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          file = ref[j];
          if (file.match(/\.cb[rtz]$/)) {
            results.push(path.resolve(this.updateDir, file));
          }
        }
        return results;
      }).call(this);
      for (j = 0, len = filesToUnpack.length; j < len; j++) {
        unpackFile = filesToUnpack[j];
        if (cfs.insideDir(unpackFile, this.archivesDir)) {
          log.verbose("Skipping archive " + unpackFile + " ...");
          continue;
        }
        parsed = path.parse(unpackFile);
        unpackDir = cfs.join(parsed.dir, parsed.name);
        log.verbose("Processing " + unpackFile + " ...");
        this.unpack(unpackFile, unpackDir, this.force);
      }
      imageDirs = (function() {
        var k, len1, ref, results;
        ref = cfs.listDir(this.updateDir);
        results = [];
        for (k = 0, len1 = ref.length; k < len1; k++) {
          file = ref[k];
          if (file.match(/images$/)) {
            results.push(path.resolve(this.updateDir, file));
          }
        }
        return results;
      }).call(this);
      prevDir = "";
      for (i = k = 0, len1 = imageDirs.length; k < len1; i = ++k) {
        imageDir = imageDirs[i];
        parsed = path.parse(imageDir);
        if (parsed.dir) {
          comicDir = parsed.dir;
          parent = path.parse(parsed.dir);
          nextDir = "";
          comicName = parent.name;
          if (i + 1 < imageDirs.length) {
            nextParsed = path.parse(imageDirs[i + 1]);
            if (nextParsed.dir) {
              nextParent = path.parse(nextParsed.dir);
              if (nextParent.name && (parent.dir === nextParent.dir)) {
                nextDir = "../" + nextParent.name;
              }
            }
          }
          comicGenerator = new ComicGenerator(this.rootDir, comicDir, prevDir, nextDir, this.force);
          comicGenerator.generate();
          if ((nextDir.length > 0) && (comicName.length > 0)) {
            prevDir = "../" + comicName;
          } else {
            prevDir = "";
          }
        }
      }
      indexDirSeen = {};
      for (l = 0, len2 = imageDirs.length; l < len2; l++) {
        imageDir = imageDirs[l];
        imageDirPieces = imageDir.split(path.sep);
        imageDirPieces.pop();
        imageDirPieces.pop();
        while (imageDirPieces.length > 1) {
          indexDir = cfs.join.apply(null, imageDirPieces);
          indexDirSeen[indexDir] = true;
          if (indexDir === this.rootDir) {
            break;
          }
          imageDirPieces.pop();
        }
      }
      indexDirs = Object.keys(indexDirSeen).sort().reverse();
      for (m = 0, len3 = indexDirs.length; m < len3; m++) {
        indexDir = indexDirs[m];
        indexGenerator = new IndexGenerator(this.rootDir, indexDir, this.force, this.download);
        indexGenerator.generate();
      }
      if (indexDirs.length === 0) {
        this.error("No comics found. Please add at least one .cbr, .cbt, .cbz to a subdirectory and run this command again.");
      }
      return true;
    };

    Crackers.prototype.unpack = function(file, dir, force) {
      var metaFilename, unpackRequired, unpacker, valid;
      if (!cfs.prepareComicDir(dir)) {
        return false;
      }
      metaFilename = cfs.join(dir, constants.META_FILENAME);
      unpackRequired = force.unpack;
      if (cfs.newer(file, metaFilename)) {
        unpackRequired = true;
      }
      if (unpackRequired) {
        log.progress("Unpacking " + file + " into " + dir);
        unpacker = new Unpacker(file, dir);
        valid = unpacker.unpack();
        unpacker.cleanup();
        if (!valid) {
          return false;
        }
      } else {
        log.verbose("Unpack not required: (" + file + " older than " + metaFilename + ")");
      }
      return true;
    };

    Crackers.prototype.findArchives = function(filenames) {
      var archives, cbrRegex, filename, fn, j, k, len, len1, list, rel, stat;
      archives = [];
      cbrRegex = /\.cb[rtz]$/i;
      for (j = 0, len = filenames.length; j < len; j++) {
        filename = filenames[j];
        if (!fs.existsSync(filename)) {
          log.warning("Ignoring nonexistent filename: " + filename);
          continue;
        }
        stat = fs.statSync(filename);
        if (stat.isFile()) {
          if (filename.match(cbrRegex)) {
            archives.push({
              abs: filename,
              rel: null
            });
          }
        } else if (stat.isDirectory()) {
          list = cfs.listDir(filename);
          for (k = 0, len1 = list.length; k < len1; k++) {
            fn = list[k];
            fn = path.resolve(filename, fn);
            if (fn.match(cbrRegex)) {
              rel = path.relative(filename, fn);
              archives.push({
                abs: fn,
                rel: rel
              });
            }
          }
        } else {
          log.warning("Ignoring unrecognized filename: " + filename);
        }
      }
      return archives;
    };

    Crackers.prototype.processTemplate = function(template, name, skipCount) {
      var issueRegex, keys, match, output;
      keys = {};
      issueRegex = (function() {
        switch (skipCount) {
          case 3:
            return /^(\D*\d+\D+\d+\D+\d+\D+)(\d+)/;
          case 2:
            return /^(\D*\d+\D+\d+\D+)(\d+)/;
          case 1:
            return /^(\D*\d+\D+)(\d+)/;
          default:
            return /^(\D*)(\d+)/;
        }
      })();
      match = name.match(issueRegex);
      if (match) {
        keys.name = match[1];
        keys.name = keys.name.replace(/[\. ]+$/, '');
        keys.issue = match[2];
      } else {
        return name;
      }
      output = template;
      output = output.replace(/\{([^\}]+)\}/g, function(match, key) {
        var pieces, places, ref, ref1, replacement;
        replacement = (ref = keys[key]) != null ? ref : "";
        pieces = key.split(/\./);
        if (pieces.length > 1) {
          replacement = (ref1 = keys[pieces[0]]) != null ? ref1 : "";
          places = parseInt(pieces[1]);
          if (replacement.length < places) {
            replacement = "00000000000000000000000000000" + replacement;
            replacement = replacement.substr(replacement.length - places);
          }
        }
        return replacement;
      });
      output = output.replace(/^[ \/]+/, '');
      output = output.replace(/[ \/]+$/, '');
      return output;
    };

    Crackers.prototype.organize = function(args) {
      var archive, archives, dst, dstDir, j, len, madeDir, mergeDst, mkdirCmd, mvCmd, parsed, processed, ref, skip, src, template;
      mergeDst = null;
      if (args.hasOwnProperty('dst')) {
        mergeDst = args.dst;
      }
      archives = this.findArchives(args.filenames);
      if (archives.length === 0) {
        log.warning("organize: Nothing to do!");
        return;
      }
      skip = (ref = args.skip) != null ? ref : 0;
      template = args.template;
      if (!template) {
        template = "{name}/{issue.3}";
      }
      template = template.replace(/\\/g, '/');
      template = template.replace(/\/\//g, '/');
      template = template.replace(/\//g, path.sep);
      madeDir = {};
      mvCmd = "mv";
      if (process.platform === 'win32') {
        mvCmd = "rename";
      }
      mkdirCmd = "mkdir -p";
      if (process.platform === 'win32') {
        mkdirCmd = "mkdir";
      }
      for (j = 0, len = archives.length; j < len; j++) {
        archive = archives[j];
        src = archive.abs;
        if (mergeDst === null) {
          parsed = path.parse(src);
          processed = this.processTemplate(template, parsed.name, skip);
          if (parsed.dir.length === 0) {
            parsed.dir = '.';
          }
          dst = cfs.join(parsed.dir, processed) + parsed.ext;
        } else {
          if (archive.rel === null) {
            parsed = path.parse(src);
            processed = this.processTemplate(template, parsed.name, skip);
            dst = cfs.join(mergeDst, processed) + parsed.ext;
          } else {
            dst = path.resolve(mergeDst, archive.rel);
          }
        }
        parsed = path.parse(dst);
        dstDir = parsed.dir;
        if (!madeDir[dstDir] && !cfs.dirExists(dstDir)) {
          madeDir[dstDir] = true;
          if (args.execute) {
            console.log(" Mkdir: \"" + dstDir + "\"");
            wrench.mkdirSyncRecursive(dstDir);
          } else {
            console.log(mkdirCmd + " \"" + dstDir + "\"");
          }
        }
        if (src === dst) {
          if (args.execute) {
            console.log("Skip  : \"" + src + "\"");
          }
        } else {
          if (args.execute) {
            console.log("Rename: \"" + src + "\"");
            console.log("    to: \"" + dst + "\"");
            fs.renameSync(src, dst);
          } else {
            console.log(mvCmd + " \"" + src + "\" \"" + dst + "\"");
          }
        }
      }
    };

    Crackers.prototype.cleanup = function(args) {
      var archive, archivedCount, archives, archivesDir, cmd, filename, j, len, parsed, processedCount, rootDir;
      archives = this.findArchives(args.filenames);
      archivedCount = 0;
      processedCount = 0;
      cmd = "rm";
      if (process.platform === 'win32') {
        cmd = "del";
      }
      for (j = 0, len = archives.length; j < len; j++) {
        archive = archives[j];
        filename = archive.abs;
        parsed = path.parse(filename);
        rootDir = cfs.findParentContainingFilename(filename, constants.ROOT_FILENAME);
        if (!rootDir) {
          log.warning("Skipping " + filename + ", not in a crackers root");
          continue;
        }
        archivesDir = cfs.join(rootDir, constants.ARCHIVES_DIR);
        if (cfs.insideDir(filename, archivesDir)) {
          archivedCount += 1;
          log.verbose("Skipping archived comic: " + filename);
          continue;
        }
        if (args.execute) {
          console.log("Removing: " + filename);
          fs.unlinkSync(filename);
        } else {
          console.log(cmd + " \"" + filename + "\"");
        }
        processedCount += 1;
      }
      if (processedCount === 0) {
        log.warning("cleanup: Nothing to do! (skipped " + archivedCount + " archived comics)");
        return;
      }
    };

    Crackers.prototype.archiveComic = function(comicDir, archiveFilename) {
      var args;
      if (cfs.fileExists(archiveFilename)) {
        fs.unlinkSync(archiveFilename);
      }
      args = ['-r0', archiveFilename, 'images'];
      return exec('zip', args, comicDir);
    };

    Crackers.prototype.archive = function(args) {
      var archiveDir, archiveFilename, comic, comics, filename, j, k, len, len1, parsed, ref, rootDir;
      ref = args.filenames;
      for (j = 0, len = ref.length; j < len; j++) {
        filename = ref[j];
        rootDir = cfs.findParentContainingFilename(filename, constants.ROOT_FILENAME);
        if (!rootDir) {
          log.warning("Skipping " + filename + ", not in a crackers root");
          continue;
        }
        comics = cfs.gatherComics(filename, rootDir);
        for (k = 0, len1 = comics.length; k < len1; k++) {
          comic = comics[k];
          archiveFilename = cfs.join(rootDir, constants.ARCHIVES_DIR, comic.relativeDir + ".cbz");
          parsed = path.parse(archiveFilename);
          archiveDir = parsed.dir;
          wrench.mkdirSyncRecursive(archiveDir);
          if (!cfs.prepareDir(archiveDir)) {
            continue;
          }
          if (args.force || cfs.newer(comic.dir, archiveFilename)) {
            log.progress("[pack] " + comic.dir + " -> " + archiveFilename);
            this.archiveComic(comic.dir, archiveFilename);
          } else {
            log.progress("[skip] " + comic.dir + " -> " + archiveFilename);
            continue;
          }
        }
      }
    };

    return Crackers;

  })();

  module.exports = Crackers;

}).call(this);
