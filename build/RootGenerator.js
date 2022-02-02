// Generated by CoffeeScript 1.9.3
(function() {
  var ManifestGenerator, RootGenerator, StockGenerator, UpdatesGenerator, cfs, constants, fs, log, path, template;

  cfs = require('./cfs');

  constants = require('./constants');

  fs = require('fs');

  log = require('./log');

  path = require('path');

  template = require('./template');

  ManifestGenerator = require('./ManifestGenerator');

  UpdatesGenerator = require('./UpdatesGenerator');

  StockGenerator = require('./StockGenerator');

  RootGenerator = (function() {
    function RootGenerator(rootDir, force, download) {
      this.rootDir = rootDir;
      this.force = force;
      this.download = download;
      this.indexFilename = cfs.join(this.rootDir, constants.INDEX_FILENAME);
      this.rootDir = this.rootDir.replace(path.sep + "$", "");
      this.title = cfs.getRootTitle(this.rootDir);
    }

    RootGenerator.prototype.generate = function() {
      var auth, endpoint, manifestGenerator, outputText, progressEnabled, stock, updates;
      manifestGenerator = new ManifestGenerator(this.rootDir);
      manifestGenerator.generate();
      log.progress("Updated client and server manifests");
      updates = new UpdatesGenerator(this.rootDir).getUpdates();
      fs.writeFileSync(cfs.join(this.rootDir, constants.UPDATES_FILENAME), JSON.stringify(updates, null, 2));
      log.progress("Updated updates manifest");
      stock = new StockGenerator(this.rootDir).getStock();
      fs.writeFileSync(cfs.join(this.rootDir, constants.STOCK_FILENAME), stock);
      log.progress("Updated stock");
      auth = "";
      if (endpoint = cfs.getProgressEndpoint(this.rootDir)) {
        progressEnabled = "true";
        auth = cfs.getAuthEndpoint(this.rootDir);
      } else {
        progressEnabled = "false";
        endpoint = constants.MANIFEST_CLIENT_FILENAME;
      }
      outputText = template('index_html', {
        title: this.title,
        endpoint: endpoint,
        progress: progressEnabled,
        auth: auth
      });
      fs.writeFileSync(this.indexFilename, outputText);
      log.verbose("Wrote " + this.indexFilename);
      return log.progress("Updated app (index.html)");
    };

    return RootGenerator;

  })();

  module.exports = RootGenerator;

}).call(this);
