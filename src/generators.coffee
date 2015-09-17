cfs = require './cfs'
constants = require './constants'
exec = require './exec'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

class CoverGenerator
  constructor: (@rootDir, @dir, @images, @force) ->

  generateImage: (src, dst) ->
    if @force.cover or cfs.newer(src, dst)
      log.verbose "Generating thumbnail: #{src} -> #{dst}"
      exec('convert', ['-resize', "#{constants.COVER_WIDTH}x", src, dst], @dir)

  generate: ->
    if @images.length > 0
      @generateImage(path.resolve(@dir, @images[0]), cfs.join(@dir, constants.COVER_FILENAME))
      @generateImage(path.resolve(@dir, @images[@images.length - 1]), cfs.join(@dir, constants.RECENT_COVER_FILENAME))

#    count = Math.min(@images.length - 1, 15)
#    if count > 0
#      for i in [1...count]
#        offset = i * Math.floor(constants.COVER_WIDTH / 15)
#        exec('composite', ['-geometry', "+#{offset}+#{offset}", path.resolve(@dir, @images[i]), @filename, @filename], @dir)

class ComicGenerator
  constructor: (@rootDir, @dir, @nextDir, @force) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @imagesDir = cfs.join(@dir, constants.IMAGES_DIR)
    @images = cfs.listImages(@imagesDir)
    @relativeRoot = path.relative(@dir, @rootDir)
    @relativeRoot = '.' if @relativeRoot.length == 0

    @rootDir = @rootDir.replace("#{path.sep}$", "")
    tmp = @dir.substr(@rootDir.length + 1)
    pieces = tmp.split(path.sep)
    @title = pieces.join(" | ")

  generate: ->
    if @images.length == 0
      log.error "No images in '#{@dir}', removing index"
      fs.unlinkSync(@indexFilename)
      cfs.removeMetadata(@dir)
      return false

    listText = ""
    for image in @images
      parsed = path.parse(image)
      href = "#{constants.IMAGES_DIR}/#{parsed.base}"
      href = href.replace("#", "%23")
      listText += template('image_html', { href: href })
    outputText = template('comic_html', {
      generator: 'comic'
      root: @relativeRoot
      title: @title
      list: listText
      prev: "../"
      next: @nextDir
    })

    coverGenerator = new CoverGenerator(@rootDir, @dir, @images, @force)
    coverGenerator.generate()

    cfs.writeMetadata @dir, {
      type:  'comic'
      title: @title
      pages: @images.length
      count: 1
      cover: constants.COVER_FILENAME
      recentcover: constants.RECENT_COVER_FILENAME
      timestamp: cfs.dirTime(@imagesDir)
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated comic: #{@title} (#{@images.length} pages, next: '#{@nextDir}')"
    return true

class IndexGenerator
  constructor: (@rootDir, @dir, @force, @download) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @relativeRoot = path.relative(@dir, @rootDir)
    @relativeRoot = '.' if @relativeRoot.length == 0
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @isRoot = (@rootDir == @dir)
    @path = @dir.substr(@rootDir.length + 1)
    @title = @path
    if @title.length == 0
      @title = cfs.getRootTitle(@rootDir)

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
    if @isRoot and (mdList.length > 0)
      listText += template('ie_sort_html', {
        title: @title
      })
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
    prevDir = ""
    if not @isRoot
      prevDir = "../"
    outputText = template('index_html', {
      generator: 'index'
      root: @relativeRoot
      title: @title
      list: listText
      prev: prevDir
    })

    cfs.writeMetadata @dir, {
      type:  'index'
      title: @title
      count: totalCount
      cover: constants.COVER_FILENAME
      recentcover: constants.RECENT_COVER_FILENAME
      timestamp: timestamp
      recent: recent
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated index: #{@title} (#{totalCount} comics)"

class MobileGenerator
  constructor: (@rootDir) ->
    @mobileFilename = cfs.join(@rootDir, constants.MOBILE_FILENAME)

  generate: ->
    outputText = template('mobile_html', { title: cfs.getRootTitle(@rootDir) })
    fs.writeFileSync @mobileFilename, outputText
    log.progress "Generated mobile page (#{constants.MOBILE_FILENAME})"

module.exports =
  CoverGenerator:  CoverGenerator
  ComicGenerator:  ComicGenerator
  IndexGenerator:  IndexGenerator
  MobileGenerator: MobileGenerator
