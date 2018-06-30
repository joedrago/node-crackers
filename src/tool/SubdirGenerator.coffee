cfs = require './cfs'
constants = require './constants'
log = require './log'
path = require 'path'

CoverGenerator = require './CoverGenerator'

class SubdirGenerator
  constructor: (@rootDir, @dir, @force, @download) ->
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    pieces = @dir.substr(@rootDir.length + 1).split(path.sep)
    @title = pieces.join(" | ")

  generate: ->
    mdList = cfs.gatherMetadata(@dir)
    if mdList.length == 0
      log.error "Nothing in '#{@dir}', removing metadata"
      cfs.removeMetadata(@dir)
      return false

    # Find images inside of this dir to find a good pair of covers (oldest and newest)
    images = (path.join(@dir, md.path, constants.COVER_FILENAME) for md in mdList)
    coverGenerator = new CoverGenerator(@rootDir, @dir, images, @force)
    coverGenerator.generate()

    # Walk all child metadata to come up with this subdir's metadata
    totalCount = 0
    timestamp = 0
    recent = ""

    for metadata in mdList
      if timestamp < metadata.timestamp
        timestamp = metadata.timestamp
        recent = metadata.path
      totalCount += metadata.count

    if mdList[0].type == 'comic'
      absoluteFirstDir = path.resolve(@dir, mdList[0].path)
      firstDir = path.relative(@rootDir, absoluteFirstDir).replace(/\\/g, "/")
    else
      firstDir = mdList[0].first

    # Write out metadata
    cfs.writeMetadata @dir, {
      type:  'index'
      title: @title
      count: totalCount
      timestamp: timestamp
      recent: recent
      first: firstDir
    }
    log.progress "Updated subdir: #{@title}"

module.exports = SubdirGenerator
