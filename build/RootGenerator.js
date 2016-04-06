// Generated by CoffeeScript 1.9.3
(function() {
  var CoverGenerator, ManifestGenerator, RootGenerator, UpdatesGenerator, cfs, constants, fs, log, path, template;

  cfs = require('./cfs');

  constants = require('./constants');

  fs = require('fs');

  log = require('./log');

  path = require('path');

  template = require('./template');

  CoverGenerator = require('./CoverGenerator');

  ManifestGenerator = require('./ManifestGenerator');

  UpdatesGenerator = require('./UpdatesGenerator');

  RootGenerator = (function() {
    function RootGenerator(rootDir, dir, force, download) {
      var pieces;
      this.rootDir = rootDir;
      this.dir = dir;
      this.force = force;
      this.download = download;
      this.indexFilename = cfs.join(this.dir, constants.INDEX_FILENAME);
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

    RootGenerator.prototype.generate = function() {
      var coverGenerator, endpoint, i, images, len, manifestGenerator, md, mdList, metadata, outputText, progressEnabled, recent, timestamp, totalCount, updates;
      mdList = cfs.gatherMetadata(this.dir);
      if (mdList.length === 0) {
        log.error("Nothing in '" + this.dir + "', removing index");
        fs.unlinkSync(this.indexFilename);
        cfs.removeMetadata(this.dir);
        return false;
      }
      if (this.isRoot) {
        manifestGenerator = new ManifestGenerator(this.rootDir);
        manifestGenerator.generate();
        updates = new UpdatesGenerator(this.rootDir).getUpdates();
        fs.writeFileSync(cfs.join(this.dir, constants.UPDATES_FILENAME), JSON.stringify(updates, null, 2));
        if (endpoint = cfs.getProgressEndpoint(this.rootDir)) {
          progressEnabled = "true";
        } else {
          progressEnabled = "false";
          endpoint = constants.MANIFEST_CLIENT_FILENAME;
        }
        outputText = template('index_html', {
          title: this.title,
          endpoint: endpoint,
          progress: progressEnabled
        });
        fs.writeFileSync(this.indexFilename, outputText);
        log.verbose("Wrote " + this.indexFilename);
      }
      if (!this.isRoot) {
        images = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = mdList.length; i < len; i++) {
            md = mdList[i];
            results.push(path.join(this.dir, md.path, constants.COVER_FILENAME));
          }
          return results;
        }).call(this);
        coverGenerator = new CoverGenerator(this.rootDir, this.dir, images, this.force);
        coverGenerator.generate();
      }
      totalCount = 0;
      timestamp = 0;
      recent = "";
      for (i = 0, len = mdList.length; i < len; i++) {
        metadata = mdList[i];
        if (timestamp < metadata.timestamp) {
          timestamp = metadata.timestamp;
          recent = metadata.path;
        }
        totalCount += metadata.count;
      }
      cfs.writeMetadata(this.dir, {
        type: 'index',
        title: this.title,
        count: totalCount,
        timestamp: timestamp,
        recent: recent
      });
      return log.progress("Updated metadata: " + this.title);
    };

    return RootGenerator;

  })();

  module.exports = RootGenerator;

}).call(this);
