cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
template = require './template'

class ComicGenerator
  constructor: (@rootDir, @dir) ->
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
      return false

    listText = ""
    for image in @images
      parsed = path.parse(image)
      href = "#{constants.IMAGES_DIR}/#{parsed.base}"
      href = href.replace("#", "%23")
      listText += template('image', { href: href })
    outputText = template('comic', { title: @title, list: listText })

    cfs.writeMetadata @dir, {
      type:  'comic'
      title: @title
      pages: @images.length
      count: 1
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated comic: #{@title}"
    return true

class IndexGenerator
  constructor: (@rootDir, @dir) ->
    @indexFilename = cfs.join(@dir, constants.INDEX_FILENAME)
    @rootDir = @rootDir.replace("#{path.sep}$", "")
    @title = @dir.substr(@rootDir.length + 1)
    if @title.length == 0
      @title = "Crackers"

  generate: ->
    indexList = cfs.gatherIndex(@dir)

    listText = ""
    totalCount = 0
    for file in indexList
      totalCount += file.count
      switch file.type
        when 'comic'
          listText += template('ie_comic', { path: file.path, title: file.path })
        when 'index'
          listText += template('ie_index', { path: file.path, title: file.path, count: file.count })
    outputText = template('index', { title: @title, list: listText })

    cfs.writeMetadata @dir, {
      type:  'index'
      count: totalCount
    }
    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated index: #{@title} (#{totalCount} comics)"

module.exports =
  IndexGenerator: IndexGenerator
  ComicGenerator: ComicGenerator
