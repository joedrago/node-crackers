cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

ManifestGenerator = require './ManifestGenerator'
UpdatesGenerator = require './UpdatesGenerator'
StockGenerator = require './StockGenerator'

class RootGenerator
  constructor: (@rootDir, @force, @download) ->
    @indexFilename = cfs.join(@rootDir, constants.INDEX_FILENAME)
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @title = cfs.getRootTitle(@rootDir)

  generate: ->
    # Generate client and server manifests
    manifestGenerator = new ManifestGenerator(@rootDir)
    manifestGenerator.generate()
    log.progress "Updated client and server manifests"

    # Generate updates manifest
    updates = new UpdatesGenerator(@rootDir).getUpdates()
    fs.writeFileSync cfs.join(@rootDir, constants.UPDATES_FILENAME), JSON.stringify(updates, null, 2)
    log.progress "Updated updates manifest"

    # Generate stock
    stock = new StockGenerator(@rootDir).getStock()
    fs.writeFileSync cfs.join(@rootDir, constants.STOCK_FILENAME), stock
    log.progress "Updated stock"

    # See if the user enabled the progress endpoint in root.crackers
    if endpoint = cfs.getProgressEndpoint(@rootDir)
      progressEnabled = "true"
    else
      progressEnabled = "false"
      endpoint = constants.MANIFEST_CLIENT_FILENAME

    # Write out the client webapp into index.html
    outputText = template('index_html', {
      title: @title
      endpoint: endpoint
      progress: progressEnabled
    })
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Updated app (index.html)"

module.exports = RootGenerator
