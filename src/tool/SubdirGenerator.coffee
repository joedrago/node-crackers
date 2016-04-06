cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

CoverGenerator = require './CoverGenerator'
ManifestGenerator = require './ManifestGenerator'
UpdatesGenerator = require './UpdatesGenerator'

class SubdirGenerator
  constructor: (@rootDir, @dir, @force, @download) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @isRoot = (@rootDir == @dir)
    @path = @dir.substr(@rootDir.length + 1)
    @title = @path
    if @title.length == 0
      @title = cfs.getRootTitle(@rootDir)
    else
      pieces = @title.split(path.sep)
      @title = pieces.join(" | ")

  generate: ->
    mdList = cfs.gatherMetadata(@dir)
    if mdList.length == 0
      log.error "Nothing in '#{@dir}', removing index"
      fs.unlinkSync(@indexFilename)
      cfs.removeMetadata(@dir)
      return false

    if @isRoot
      manifestGenerator = new ManifestGenerator(@rootDir)
      manifestGenerator.generate()
      updates = new UpdatesGenerator(@rootDir).getUpdates()
      fs.writeFileSync cfs.join(@dir, constants.UPDATES_FILENAME), JSON.stringify(updates, null, 2)

      if endpoint = cfs.getProgressEndpoint(@rootDir)
        progressEnabled = "true"
      else
        progressEnabled = "false"
        endpoint = constants.MANIFEST_CLIENT_FILENAME

      outputText = template('index_html', {
        title: @title
        endpoint: endpoint
        progress: progressEnabled
      })
      fs.writeFileSync @indexFilename, outputText
      log.verbose "Wrote #{@indexFilename}"

    if not @isRoot
      images = (path.join(@dir, md.path, constants.COVER_FILENAME) for md in mdList)
      coverGenerator = new CoverGenerator(@rootDir, @dir, images, @force)
      coverGenerator.generate()

    totalCount = 0
    timestamp = 0
    recent = ""
    for metadata in mdList
      if timestamp < metadata.timestamp
        timestamp = metadata.timestamp
        recent = metadata.path
      totalCount += metadata.count

    cfs.writeMetadata @dir, {
      type:  'index'
      title: @title
      count: totalCount
      timestamp: timestamp
      recent: recent
    }
    log.progress "Updated metadata: #{@title}"

module.exports = SubdirGenerator
