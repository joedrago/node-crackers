cfs = require './cfs'
constants = require './constants'
log = require './log'
path = require 'path'

class CoverGenerator
  constructor: (@rootDir, @dir, @images, @force) ->

  generateImage: (src, dst) ->
    if @force.cover or cfs.newer(src, dst)
      log.verbose "Generating thumbnail: #{src} -> #{dst}"

  generate: ->
    if @images.length > 0
      @generateImage(path.resolve(@dir, @images[0]), cfs.join(@dir, constants.COVER_FILENAME))
      @generateImage(path.resolve(@dir, @images[@images.length - 1]), cfs.join(@dir, constants.RECENT_COVER_FILENAME))

module.exports = CoverGenerator
