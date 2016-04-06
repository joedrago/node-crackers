cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

CoverGenerator = require './CoverGenerator'

class ComicGenerator
  constructor: (@rootDir, @dir, @prevDir, @nextDir, @force) ->
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
      log.error "No images in '#{@dir}', removing metadata"
      cfs.removeMetadata(@dir)
      return false

    imageUrls = []
    for image in @images
      parsed = path.parse(image)
      url = "#{constants.IMAGES_DIR}/#{parsed.base}"
      url = url.replace("#", "%23")
      imageUrls.push "#{@relativeDir}/#{url}".replace(/\\/g, "/")

    coverGenerator = new CoverGenerator(@rootDir, @dir, [ @images[0] ], @force)
    coverGenerator.generate()

    cfs.writeMetadata @dir, {
      type:  'comic'
      title: @title
      pages: @images.length
      count: 1
      prev: @prevDir
      next: @nextDir
      timestamp: cfs.dirTime(@imagesDir)
      images: imageUrls
    }
    log.progress "Updated comic: #{@title} (#{@images.length} pages)"
    return true

module.exports = ComicGenerator
