cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

CoverGenerator = require './CoverGenerator'

class ComicGenerator
  constructor: (@rootDir, @dir, @prevDir, @nextDir, @force) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @imagesDir = cfs.join(@dir, constants.IMAGES_DIR)
    @images = cfs.listImages(@imagesDir)
    @relativeRoot = path.relative(@dir, @rootDir)
    @relativeRoot = '.' if @relativeRoot.length == 0

    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @relativeDir = @dir.substr(@rootDir.length + 1)
    pieces = @relativeDir.split(path.sep)
    @title = pieces.join(" | ")

  generate: ->
    if @images.length == 0
      log.error "No images in '#{@dir}', removing index"
      fs.unlinkSync(@indexFilename)
      cfs.removeMetadata(@dir)
      return false

    listText = ""
    jsList = ""
    imageUrls = []
    for image in @images
      parsed = path.parse(image)
      url = "#{constants.IMAGES_DIR}/#{parsed.base}"
      url = url.replace("#", "%23")
      imageUrls.push "#{@relativeDir}/#{url}"
      listText += template('image_html', { url: url })
      jsList += template('image_js', { url: url })
    outputText = template('comic_html', {
      generator: 'comic'
      dir: @relativeDir
      root: @relativeRoot
      title: @title
      list: listText
      jslist: jsList
      prev: @prevDir
      next: @nextDir
    })

    coverGenerator = new CoverGenerator(@rootDir, @dir, [ @images[0] ], @force)
    coverGenerator.generate()

    cfs.writeMetadata @dir, {
      type:  'comic'
      title: @title
      pages: @images.length
      count: 1
      cover: constants.COVER_FILENAME
      recentcover: constants.RECENT_COVER_FILENAME
      timestamp: cfs.dirTime(@imagesDir)
      images: imageUrls
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated comic: #{@title} (#{@images.length} pages, next: '#{@nextDir}')"
    return true

module.exports = ComicGenerator
