// Generated by CoffeeScript 1.9.3
(function() {
  var Unpacker, cfs, constants, exec, fs, log, path, touch, which;

  fs = require('fs');

  cfs = require('./cfs');

  constants = require('./constants');

  exec = require('./exec');

  log = require('./log');

  path = require('path');

  touch = require('touch');

  which = require('which');

  Unpacker = (function() {
    function Unpacker(archive, dir) {
      var now;
      this.archive = archive;
      this.dir = dir;
      this.detectFormat();
      now = String(Math.floor(new Date() / 1000));
      this.tempDir = cfs.join(this.dir, constants.TEMP_UNPACK_DIR + "." + now);
      this.imagesDir = cfs.join(this.dir, constants.IMAGES_DIR);
      this.deadImagesDir = this.imagesDir + "." + now;
      this.valid = false;
    }

    Unpacker.prototype.cleanup = function() {
      cfs.cleanupDir(this.tempDir);
      cfs.cleanupDir(this.deadImagesDir);
      if (!this.valid) {
        return cfs.cleanupDir(this.imagesDir);
      }
    };

    Unpacker.prototype.readHeader = function() {
      var buffer, bytesRead, fd;
      fd = fs.openSync(this.archive, 'r');
      buffer = Buffer.alloc(2);
      bytesRead = fs.readSync(fd, buffer, 0, 2, 0);
      fs.closeSync(fd);
      if (bytesRead === 2) {
        return buffer.toString();
      }
      return false;
    };

    Unpacker.prototype.detectFormat = function() {
      var header;
      this.type = 'cbr';
      if (this.archive.match(/cbt$/)) {
        this.type = 'cbt';
      }
      if (this.archive.match(/cbz$/)) {
        this.type = 'cbz';
      }
      header = this.readHeader();
      if (header) {
        switch (header) {
          case 'Ra':
            this.type = 'cbr';
            break;
          case 'PK':
            this.type = 'cbz';
        }
      }
      return log.verbose("Detected format for " + this.archive + ": " + this.type);
    };

    Unpacker.prototype.unpack = function() {
      var args, cmd, dimensionMap, dimensions, dims, finalImagePath, heightMap, heights, i, identifyData, image, images, j, len, len1, maxToleranceH, maxToleranceW, mostCommonHeight, mostCommonWidth, parsed, pieces, rotToleranceH, rotToleranceW, skipImage, toleranceH, toleranceW, validDimsCount, widthMap, widths;
      log.verbose("Unpacker: type " + this.type + " " + this.archive + " -> " + this.dir);
      log.verbose("Unpacker: @tempDir " + this.tempDir);
      if (!cfs.prepareDir(this.tempDir)) {
        log.error("Could not create temp dir for unpacking");
        return false;
      }
      if (this.type === 'cbr') {
        cmd = 'unrar';
        args = ['x', this.archive];
      } else if (this.type === 'cbt') {
        cmd = 'tar';
        args = ['xf', this.archive];
      } else {
        cmd = 'unzip';
        args = [this.archive];
      }
      exec(cmd, args, this.tempDir);
      cfs.chmodSyncRecursive(this.tempDir, 0x1ed);
      if (fs.existsSync(this.imagesDir)) {
        log.verbose("moving old images dir " + this.imagesDir + " to " + this.deadImagesDir);
        fs.renameSync(this.imagesDir, this.deadImagesDir);
      }
      if (!cfs.prepareDir(this.imagesDir)) {
        log.error("Could not create images dir");
        return false;
      }
      images = cfs.listImages(this.tempDir);
      if (!images.length) {
        return false;
      }
      dimensionMap = {};
      widthMap = {};
      heightMap = {};
      validDimsCount = 0;
      skipImage = {};
      for (i = 0, len = images.length; i < len; i++) {
        image = images[i];
        identifyData = exec('identify', ['-format', '%w %h', image]);
        pieces = identifyData.replace(/\n/, '').split(/ /);
        if (pieces.length !== 2) {
          skipImage[image] = true;
          continue;
        }
        dimensions = {
          width: parseInt(pieces[0]),
          height: parseInt(pieces[1])
        };
        if ((dimensions.width < 1) || (dimensions.height < 1)) {
          skipImage[image] = true;
          continue;
        }
        dimensionMap[image] = dimensions;
        if ((dimensions.width < 10) || (dimensions.width < 10)) {
          continue;
        }
        dimensions.width = Math.round(dimensions.width / 100) * 100;
        dimensions.height = Math.round(dimensions.height / 100) * 100;
        if (!widthMap[dimensions.width]) {
          widthMap[dimensions.width] = 1;
        } else {
          widthMap[dimensions.width] += 1;
        }
        if (!heightMap[dimensions.height]) {
          heightMap[dimensions.height] = 1;
        } else {
          heightMap[dimensions.height] += 1;
        }
        validDimsCount += 1;
      }
      if (validDimsCount > 0) {
        widths = Object.keys(widthMap).sort(function(a, b) {
          if (widthMap[a] === widthMap[b]) {
            return 0;
          }
          if (widthMap[a] > widthMap[b]) {
            return -1;
          }
          return 1;
        });
        heights = Object.keys(heightMap).sort(function(a, b) {
          if (heightMap[a] === heightMap[b]) {
            return 0;
          }
          if (heightMap[a] > heightMap[b]) {
            return -1;
          }
          return 1;
        });
        log.verbose("widthMap", widthMap);
        log.verbose("heightMap", heightMap);
        mostCommonWidth = widths[0];
        mostCommonHeight = heights[0];
      }
      maxToleranceW = mostCommonWidth * constants.SPAM_SIZE_TOLERANCE;
      maxToleranceH = mostCommonHeight * constants.SPAM_SIZE_TOLERANCE;
      for (j = 0, len1 = images.length; j < len1; j++) {
        image = images[j];
        if (skipImage[image]) {
          log.warning("Skipping bad image: " + image);
          continue;
        }
        dims = dimensionMap[image];
        toleranceW = mostCommonWidth - dims.width;
        toleranceH = mostCommonHeight - dims.height;
        if ((toleranceW > maxToleranceW) || (toleranceH > maxToleranceH)) {
          rotToleranceW = mostCommonHeight - dims.width;
          rotToleranceH = mostCommonWidth - dims.height;
          if ((rotToleranceW > maxToleranceW) || (rotToleranceH > maxToleranceH)) {
            log.warning("Spam detected: '" + image + "' is " + dims.width + "x" + dims.height + ", not close enough to " + mostCommonWidth + "x" + mostCommonHeight);
            continue;
          }
        }
        parsed = path.parse(image);
        finalImagePath = cfs.join(this.imagesDir, parsed.base);
        if (image.match(/webp$/)) {
          finalImagePath = finalImagePath.replace(/\.webp$/, '.png');
          exec('dwebp', [image, '-o', finalImagePath], this.tempDir);
        } else {
          fs.renameSync(image, finalImagePath);
        }
        touch.sync(finalImagePath);
      }
      this.valid = true;
      return true;
    };

    return Unpacker;

  })();

  module.exports = Unpacker;

}).call(this);
