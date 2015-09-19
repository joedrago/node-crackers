// Generated by CoffeeScript 1.9.3
(function() {
  var ComicGenerator, CoverGenerator, IndexGenerator, MobileGenerator, Updates, cfs, constants, exec, fs, log, path, template;

  cfs = require('./cfs');

  constants = require('./constants');

  exec = require('./exec');

  fs = require('fs');

  log = require('./log');

  path = require('path');

  template = require('./template');

  Updates = require('./updates');

  CoverGenerator = (function() {
    function CoverGenerator(rootDir, dir, images1, force) {
      this.rootDir = rootDir;
      this.dir = dir;
      this.images = images1;
      this.force = force;
    }

    CoverGenerator.prototype.generateImage = function(src, dst) {
      if (this.force.cover || cfs.newer(src, dst)) {
        log.verbose("Generating thumbnail: " + src + " -> " + dst);
        return exec('convert', ['-resize', constants.COVER_WIDTH + "x", src, dst], this.dir);
      }
    };

    CoverGenerator.prototype.generate = function() {
      if (this.images.length > 0) {
        this.generateImage(path.resolve(this.dir, this.images[0]), cfs.join(this.dir, constants.COVER_FILENAME));
        return this.generateImage(path.resolve(this.dir, this.images[this.images.length - 1]), cfs.join(this.dir, constants.RECENT_COVER_FILENAME));
      }
    };

    return CoverGenerator;

  })();

  ComicGenerator = (function() {
    function ComicGenerator(rootDir, dir, nextDir, force) {
      var pieces, tmp;
      this.rootDir = rootDir;
      this.dir = dir;
      this.nextDir = nextDir;
      this.force = force;
      this.indexFilename = cfs.join(this.dir, constants.INDEX_FILENAME);
      this.imagesDir = cfs.join(this.dir, constants.IMAGES_DIR);
      this.images = cfs.listImages(this.imagesDir);
      this.relativeRoot = path.relative(this.dir, this.rootDir);
      if (this.relativeRoot.length === 0) {
        this.relativeRoot = '.';
      }
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
        listText += template('image_html', {
          href: href
        });
      }
      outputText = template('comic_html', {
        generator: 'comic',
        root: this.relativeRoot,
        title: this.title,
        list: listText,
        prev: "../",
        next: this.nextDir
      });
      coverGenerator = new CoverGenerator(this.rootDir, this.dir, [this.images[0]], this.force);
      coverGenerator.generate();
      cfs.writeMetadata(this.dir, {
        type: 'comic',
        title: this.title,
        pages: this.images.length,
        count: 1,
        cover: constants.COVER_FILENAME,
        recentcover: constants.RECENT_COVER_FILENAME,
        timestamp: cfs.dirTime(this.imagesDir)
      });
      fs.writeFileSync(this.indexFilename, outputText);
      log.verbose("Wrote " + this.indexFilename);
      log.progress("Generated comic: " + this.title + " (" + this.images.length + " pages, next: '" + this.nextDir + "')");
      return true;
    };

    return ComicGenerator;

  })();

  IndexGenerator = (function() {
    function IndexGenerator(rootDir, dir, force, download) {
      this.rootDir = rootDir;
      this.dir = dir;
      this.force = force;
      this.download = download;
      this.indexFilename = cfs.join(this.dir, constants.INDEX_FILENAME);
      this.updatesFilename = cfs.join(this.dir, constants.UPDATES_FILENAME);
      this.relativeRoot = path.relative(this.dir, this.rootDir);
      if (this.relativeRoot.length === 0) {
        this.relativeRoot = '.';
      }
      this.rootDir = this.rootDir.replace(path.sep + "$", "");
      this.isRoot = this.rootDir === this.dir;
      this.path = this.dir.substr(this.rootDir.length + 1);
      this.title = this.path;
      if (this.title.length === 0) {
        this.title = cfs.getRootTitle(this.rootDir);
      }
    }

    IndexGenerator.prototype.generateUpdateList = function(updates, limit) {
      var comic, i, j, len, len1, pieces, ref, remaining, text, update, updateListText;
      if (limit == null) {
        limit = 0;
      }
      text = "";
      remaining = limit;
      for (i = 0, len = updates.length; i < len; i++) {
        update = updates[i];
        updateListText = "";
        ref = update.list;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          comic = ref[j];
          pieces = comic.dir.split(path.sep);
          comic.title = pieces.join(" | ");
          if ((comic.start != null) && (comic.end != null) && (comic.start !== comic.end)) {
            updateListText += template('ue_range_html', comic);
          } else if (comic.start != null) {
            updateListText += template('ue_issue_html', comic);
          } else {
            updateListText += template('ue_single_html', comic);
          }
          if (limit) {
            remaining -= 1;
            if (remaining <= 0) {
              updateListText += template('ue_more_html', comic);
              break;
            }
          }
        }
        text += template('ue_html', {
          date: update.date,
          list: updateListText
        });
        if (limit) {
          remaining -= 1;
          if (remaining <= 0) {
            break;
          }
        }
      }
      return text;
    };

    IndexGenerator.prototype.generate = function() {
      var cover, coverGenerator, i, ieTemplate, images, len, listText, md, mdList, metadata, outputText, prevDir, recent, recentcover, timestamp, totalCount, ueTerseText, ueText, updates, updatesText;
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
      if (this.isRoot && (mdList.length > 0)) {
        updates = new Updates(this.rootDir).getUpdates();
        ueText = this.generateUpdateList(updates);
        ueTerseText = this.generateUpdateList(updates, constants.MAX_TERSE_UPDATES);
        updatesText = template('updates_html', {
          title: this.title,
          updates: ueText
        });
        fs.writeFileSync(this.updatesFilename, updatesText);
        listText += template('ie_sort_html', {
          title: this.title,
          updates: ueTerseText
        });
      }
      timestamp = 0;
      recent = "";
      for (i = 0, len = mdList.length; i < len; i++) {
        metadata = mdList[i];
        if (timestamp < metadata.timestamp) {
          timestamp = metadata.timestamp;
          recent = metadata.path;
        }
        totalCount += metadata.count;
        cover = metadata.path + "/" + metadata.cover;
        cover = cover.replace("#", "%23");
        metadata.cover = cover;
        recentcover = metadata.path + "/" + metadata.recentcover;
        recentcover = recentcover.replace("#", "%23");
        metadata.recentcover = recentcover;
        metadata.archive = cfs.findArchive(this.dir, metadata.path);
        ieTemplate = (function() {
          switch (metadata.type) {
            case 'comic':
              metadata.id = this.path + "/" + metadata.path;
              metadata.id = metadata.id.replace(/[\\\/ ]/g, "_").toLowerCase();
              if (this.download && metadata.archive) {
                return 'ie_comic_dl_html';
              } else {
                return 'ie_comic_html';
              }
              break;
            case 'index':
              return 'ie_index_html';
          }
        }).call(this);
        listText += template(ieTemplate, metadata);
      }
      prevDir = "";
      if (!this.isRoot) {
        prevDir = "../";
      }
      outputText = template('index_html', {
        generator: 'index',
        root: this.relativeRoot,
        title: this.title,
        list: listText,
        prev: prevDir
      });
      cfs.writeMetadata(this.dir, {
        type: 'index',
        title: this.title,
        count: totalCount,
        cover: constants.COVER_FILENAME,
        recentcover: constants.RECENT_COVER_FILENAME,
        timestamp: timestamp,
        recent: recent
      });
      fs.writeFileSync(this.indexFilename, outputText);
      log.verbose("Wrote " + this.indexFilename);
      return log.progress("Generated index: " + this.title + " (" + totalCount + " comics)");
    };

    return IndexGenerator;

  })();

  MobileGenerator = (function() {
    function MobileGenerator(rootDir) {
      this.rootDir = rootDir;
      this.mobileFilename = cfs.join(this.rootDir, constants.MOBILE_FILENAME);
    }

    MobileGenerator.prototype.generate = function() {
      var outputText;
      outputText = template('mobile_html', {
        title: cfs.getRootTitle(this.rootDir)
      });
      fs.writeFileSync(this.mobileFilename, outputText);
      return log.progress("Generated mobile page (" + constants.MOBILE_FILENAME + ")");
    };

    return MobileGenerator;

  })();

  module.exports = {
    CoverGenerator: CoverGenerator,
    ComicGenerator: ComicGenerator,
    IndexGenerator: IndexGenerator,
    MobileGenerator: MobileGenerator
  };

}).call(this);
