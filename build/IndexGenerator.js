// Generated by CoffeeScript 1.9.3
(function() {
  var CoverGenerator, IndexGenerator, ManifestGenerator, UpdatesGenerator, cfs, constants, fs, log, path, template;

  cfs = require('./cfs');

  constants = require('./constants');

  fs = require('fs');

  log = require('./log');

  path = require('path');

  template = require('./template');

  CoverGenerator = require('./CoverGenerator');

  ManifestGenerator = require('./ManifestGenerator');

  UpdatesGenerator = require('./UpdatesGenerator');

  IndexGenerator = (function() {
    function IndexGenerator(rootDir, dir, force, download) {
      var pieces;
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
      } else {
        pieces = this.title.split(path.sep);
        this.title = pieces.join(" | ");
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

    IndexGenerator.prototype.ensureFileExists = function(filename) {};

    IndexGenerator.prototype.generate = function() {
      var cover, coverGenerator, endpoint, i, ieTemplate, images, len, listText, manifestGenerator, md, mdList, metadata, outputText, progressEnabled, recent, recentcover, timestamp, totalCount, updates;
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
      if (this.isRoot) {
        manifestGenerator = new ManifestGenerator(this.rootDir);
        manifestGenerator.generate();
        updates = new UpdatesGenerator(this.rootDir).getUpdates();
        fs.writeFileSync(cfs.join(this.dir, constants.UPDATES_FILENAME), JSON.stringify(updates, null, 2));
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
        metadata.dir = path.join(this.dir.substr(this.rootDir.length + 1), metadata.path);
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
      if (this.isRoot) {
        endpoint = cfs.getProgressEndpoint(this.rootDir);
        progressEnabled = "true";
        if (!endpoint) {
          endpoint = constants.MANIFEST_CLIENT_FILENAME;
          progressEnabled = "false";
        }
        outputText = template('index_html', {
          generator: 'index',
          dir: this.path,
          root: this.relativeRoot,
          title: this.title,
          list: listText,
          prev: "",
          endpoint: endpoint,
          progress: progressEnabled
        });
        fs.writeFileSync(this.indexFilename, outputText);
        log.verbose("Wrote " + this.indexFilename);
      }
      cfs.writeMetadata(this.dir, {
        type: 'index',
        title: this.title,
        cover: constants.COVER_FILENAME,
        count: totalCount,
        recentcover: constants.RECENT_COVER_FILENAME,
        timestamp: timestamp,
        recent: recent
      });
      return log.progress("Updated metadata: " + this.title);
    };

    return IndexGenerator;

  })();

  module.exports = IndexGenerator;

}).call(this);
