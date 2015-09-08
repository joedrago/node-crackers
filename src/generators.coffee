cfs = require './cfs'
constants = require './constants'
exec = require './exec'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

class CoverGenerator
  constructor: (@rootDir, @dir, @images, @force) ->
    @filename = cfs.join(@dir, constants.COVER_FILENAME)
    log.verbose "CoverGenerator: creating #{@filename}"
    log.verbose "CoverGenerator: list", @images

  generate: ->
    if not @force.cover
      if cfs.fileExists(@filename)
        log.verbose "Skipping thumbnail generation, file exists: #{@filename}"
        return
    else
      log.verbose "Forcing thumbnail generation: #{@filename}"

    exec('convert', ['-resize', "#{constants.COVER_WIDTH}x", path.resolve(@dir, @images[0]), @filename], @dir)

#    count = Math.min(@images.length - 1, 15)
#    if count > 0
#      for i in [1...count]
#        offset = i * Math.floor(constants.COVER_WIDTH / 15)
#        exec('composite', ['-geometry', "+#{offset}+#{offset}", path.resolve(@dir, @images[i]), @filename, @filename], @dir)

class ComicGenerator
  constructor: (@rootDir, @dir, @nextDir, @force) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @images = cfs.listImages(cfs.join(@dir, constants.IMAGES_DIR))

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
    outputText = template('comic_html', { title: @title, list: listText, prev: "../", next: @nextDir })

    coverGenerator = new CoverGenerator(@rootDir, @dir, [ @images[0] ], @force)
    coverGenerator.generate()

    cfs.writeMetadata @dir, {
      type:  'comic'
      title: @title
      pages: @images.length
      count: 1
      cover: constants.COVER_FILENAME
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated comic: #{@title} (#{@images.length} pages, next: '#{@nextDir}')"
    return true

class IndexGenerator
  constructor: (@rootDir, @dir, @force) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @title = @dir.substr(@rootDir.length + 1)
    if @title.length == 0
      @title = constants.DEFAULT_TITLE

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
    for metadata in mdList
      totalCount += metadata.count
      cover = "#{metadata.path}/#{metadata.cover}"
      cover = cover.replace("#", "%23")
      metadata.cover = cover
      metadata.archive = cfs.findArchive(@dir, metadata.path)
      ieTemplate = switch metadata.type
        when 'comic'
          if metadata.archive
            'ie_comic_dl_html'
          else
            'ie_comic_html'
        when 'index' then 'ie_index_html'
      listText += template(ieTemplate, metadata)
    prevDir = ""
    if @rootDir != @dir
      prevDir = "../"
    outputText = template('index_html', { title: @title, list: listText, prev: prevDir })

    cfs.writeMetadata @dir, {
      type:  'index'
      title: @title
      count: totalCount
      cover: constants.COVER_FILENAME
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated index: #{@title} (#{totalCount} comics)"

module.exports =
  CoverGenerator: CoverGenerator
  ComicGenerator: ComicGenerator
  IndexGenerator: IndexGenerator
