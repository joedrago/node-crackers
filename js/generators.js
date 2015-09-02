// Generated by CoffeeScript 1.9.3
(function() {
  var ComicGenerator, CoverGenerator, IndexGenerator, cfs, constants, exec, fs, log, path, template;

  cfs = require('./cfs');

  constants = require('./constants');

  exec = require('./exec');

  fs = require('fs');

  log = require('./log');

  path = require('path');

  template = require('./template');

  CoverGenerator = (function() {
    function CoverGenerator(rootDir, dir, images1, force) {
      this.rootDir = rootDir;
      this.dir = dir;
      this.images = images1;
      this.force = force;
      this.filename = cfs.join(this.dir, constants.COVER_FILENAME);
      log.verbose("CoverGenerator: creating " + this.filename);
      log.verbose("CoverGenerator: list", this.images);
    }

    CoverGenerator.prototype.generate = function() {
      if (!this.force.cover) {
        if (cfs.fileExists(this.filename)) {
          log.verbose("Skipping thumbnail generation, file exists: " + this.filename);
          return;
        }
      } else {
        log.verbose("Forcing thumbnail generation: " + this.filename);
      }
      return exec('convert', ['-resize', constants.COVER_WIDTH + "x", path.resolve(this.dir, this.images[0]), this.filename], this.dir);
    };

    return CoverGenerator;

  })();

  ComicGenerator = (function() {
    function ComicGenerator(rootDir, dir, force) {
      var pieces, tmp;
      this.rootDir = rootDir;
      this.dir = dir;
      this.force = force;
      this.indexFilename = cfs.join(this.dir, constants.INDEX_FILENAME);
      this.images = cfs.listImages(cfs.join(this.dir, constants.IMAGES_DIR));
      this.rootDir = this.rootDir.replace(path.sep + "$", "");
      tmp = this.dir.substr(this.rootDir.length + 1);
      pieces = tmp.split(path.sep);
      this.title = pieces.join(" | ");
    }

    ComicGenerator.prototype.generate = function() {
      var coverGenerator, href, i, image, len, listText, outputText, parsed, ref;
      if (this.images.length === 0) {
        log.error("No images in '" + this.dir + "', removing index");
        fs.unlinkSync(this.indexFilename);
        cfs.removeMetadata(this.dir);
        return false;
      }
      listText = "";
      ref = this.images;
      for (i = 0, len = ref.length; i < len; i++) {
        image = ref[i];
        parsed = path.parse(image);
        href = constants.IMAGES_DIR + "/" + parsed.base;
        href = href.replace("#", "%23");
        listText += template('image', {
          href: href
        });
      }
      outputText = template('comic', {
        title: this.title,
        list: listText
      });
      coverGenerator = new CoverGenerator(this.rootDir, this.dir, [this.images[0]], this.force);
      coverGenerator.generate();
      cfs.writeMetadata(this.dir, {
        type: 'comic',
        title: this.title,
        pages: this.images.length,
        count: 1,
        cover: constants.COVER_FILENAME
      });
      fs.writeFileSync(this.indexFilename, outputText);
      log.verbose("Wrote " + this.indexFilename);
      log.progress("Generated comic: " + this.title);
      return true;
    };

    return ComicGenerator;

  })();

  IndexGenerator = (function() {
    function IndexGenerator(rootDir, dir, force) {
      this.rootDir = rootDir;
      this.dir = dir;
      this.force = force;
      this.indexFilename = cfs.join(this.dir, constants.INDEX_FILENAME);
      this.rootDir = this.rootDir.replace(path.sep + "$", "");
      this.title = this.dir.substr(this.rootDir.length + 1);
      if (this.title.length === 0) {
        this.title = constants.DEFAULT_TITLE;
      }
    }

    IndexGenerator.prototype.generate = function() {
      var cover, coverGenerator, i, ieTemplate, images, len, listText, md, mdList, metadata, outputText, totalCount;
      mdList = cfs.gatherMetadata(this.dir);
      if (mdList.length === 0) {
        log.error("Nothing in '" + this.dir + "', removing index");
        fs.unlinkSync(this.indexFilename);
        cfs.removeMetadata(this.dir);
        return false;
      }
      images = (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = mdList.length; i < len; i++) {
          md = mdList[i];
          results.push(path.join(this.dir, md.path, md.cover));
        }
        return results;
      }).call(this);
      coverGenerator = new CoverGenerator(this.rootDir, this.dir, images, this.force);
      coverGenerator.generate();
      listText = "";
      totalCount = 0;
      for (i = 0, len = mdList.length; i < len; i++) {
        metadata = mdList[i];
        totalCount += metadata.count;
        cover = metadata.path + "/" + metadata.cover;
        cover = cover.replace("#", "%23");
        metadata.cover = cover;
        metadata.archive = cfs.findArchive(this.dir, metadata.path);
        ieTemplate = (function() {
          switch (metadata.type) {
            case 'comic':
              if (metadata.archive) {
                return 'ie_comic_dl';
              } else {
                return 'ie_comic';
              }
              break;
            case 'index':
              return 'ie_index';
          }
        })();
        listText += template(ieTemplate, metadata);
      }
      outputText = template('index', {
        title: this.title,
        list: listText,
        coverwidth: constants.COVER_WIDTH
      });
      cfs.writeMetadata(this.dir, {
        type: 'index',
        title: this.title,
        count: totalCount,
        cover: constants.COVER_FILENAME
      });
      fs.writeFileSync(this.indexFilename, outputText);
      log.verbose("Wrote " + this.indexFilename);
      return log.progress("Generated index: " + this.title + " (" + totalCount + " comics)");
    };

    return IndexGenerator;

  })();

  module.exports = {
    CoverGenerator: CoverGenerator,
    ComicGenerator: ComicGenerator,
    IndexGenerator: IndexGenerator
  };

}).call(this);
