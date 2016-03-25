cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

CoverGenerator = require './CoverGenerator'
ManifestGenerator = require './ManifestGenerator'
UpdatesGenerator = require './UpdatesGenerator'

class IndexGenerator
  constructor: (@rootDir, @dir, @force, @download) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @updatesFilename = cfs.join(@dir, constants.UPDATES_FILENAME)
    @relativeRoot = path.relative(@dir, @rootDir)
    @relativeRoot = '.' if @relativeRoot.length == 0
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @isRoot = (@rootDir == @dir)
    @path = @dir.substr(@rootDir.length + 1)
    @title = @path
    if @title.length == 0
      @title = cfs.getRootTitle(@rootDir)
    else
      pieces = @title.split(path.sep)
      @title = pieces.join(" | ")

  generateUpdateList: (updates, limit = 0) ->
    text = ""
    remaining = limit
    for update in updates
      updateListText = ""
      for comic in update.list
        pieces = comic.dir.split(path.sep)
        comic.title = pieces.join(" | ")
        if comic.start? and comic.end? and (comic.start != comic.end)
          updateListText += template('ue_range_html', comic)
        else if comic.start?
          updateListText += template('ue_issue_html', comic)
        else
          updateListText += template('ue_single_html', comic)
        if limit
          remaining -= 1
          if remaining <= 0
            updateListText += template('ue_more_html', comic)
            break
      text += template('ue_html', { date: update.date, list: updateListText })
      if limit
        remaining -= 1
        break if remaining <= 0
    return text

  ensureFileExists: (filename) ->

  generate: ->
    mdList = cfs.gatherMetadata(@dir)
    if mdList.length == 0
      log.error "Nothing in '#{@dir}', removing index"
      fs.unlinkSync(@indexFilename)
      cfs.removeMetadata(@dir)
      return false

    images = (path.join(@dir, md.path, md.cover) for md in mdList)
    coverGenerator = new CoverGenerator(@rootDir, @dir, images, @force)
    coverGenerator.generate()

    listText = ""
    totalCount = 0
    if @isRoot
      # cfs.ensureFileExists(cfs.join(@rootDir, "local.js"))
      # cfs.ensureFileExists(cfs.join(@rootDir, "local.comic.js"))
      # cfs.ensureFileExists(cfs.join(@rootDir, "local.index.js"))
      # cfs.ensureFileExists(cfs.join(@rootDir, "local.css"))
      manifestGenerator = new ManifestGenerator(@rootDir)
      manifestGenerator.generate()
      # updates = new UpdatesGenerator(@rootDir).getUpdates()
      # ueText = @generateUpdateList(updates)
      # ueTerseText = @generateUpdateList(updates, constants.MAX_TERSE_UPDATES)
      # updatesText = template('updates_html', { title: @title, updates: ueText })
      # fs.writeFileSync @updatesFilename, updatesText
      # listText += template('ie_sort_html', {
      #   title: @title
      #   updates: ueTerseText
      # })

    timestamp = 0
    recent = ""
    for metadata in mdList
      if timestamp < metadata.timestamp
        timestamp = metadata.timestamp
        recent = metadata.path
      totalCount += metadata.count
      cover = "#{metadata.path}/#{metadata.cover}"
      cover = cover.replace("#", "%23")
      metadata.cover = cover
      recentcover = "#{metadata.path}/#{metadata.recentcover}"
      recentcover = recentcover.replace("#", "%23")
      metadata.recentcover = recentcover
      metadata.archive = cfs.findArchive(@dir, metadata.path)
      metadata.dir = path.join(@dir.substr(@rootDir.length + 1), metadata.path)
      ieTemplate = switch metadata.type
        when 'comic'
          metadata.id = "#{@path}/#{metadata.path}"
          metadata.id = metadata.id.replace(/[\\\/ ]/g, "_").toLowerCase()
          if @download and metadata.archive
            'ie_comic_dl_html'
          else
            'ie_comic_html'
        when 'index' then 'ie_index_html'
      listText += template(ieTemplate, metadata)

    if @isRoot
      endpoint = cfs.getProgressEndpoint(@rootDir)
      progressEnabled = "true"
      if not endpoint
        endpoint = constants.MANIFEST_CLIENT_FILENAME
        progressEnabled = "false"

      outputText = template('index_html', {
        generator: 'index'
        dir: @path
        root: @relativeRoot
        title: @title
        list: listText
        prev: ""
        endpoint: endpoint
        progress: progressEnabled
      })
      fs.writeFileSync @indexFilename, outputText
      log.verbose "Wrote #{@indexFilename}"

    cfs.writeMetadata @dir, {
      type:  'index'
      title: @title
      cover: constants.COVER_FILENAME
      count: totalCount
      recentcover: constants.RECENT_COVER_FILENAME
      timestamp: timestamp
      recent: recent
    }
    log.progress "Updated metadata: #{@title}"

module.exports = IndexGenerator
