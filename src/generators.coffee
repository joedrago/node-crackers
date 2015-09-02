cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'

class ComicGenerator
  constructor: (@rootDir, @dir) ->
    @templateFilename = __dirname + "/../templates/comic.html"
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

    rawTemplate = fs.readFileSync(@templateFilename)
    templateLines = String(rawTemplate).split(/(?:\n|\r\n|\r)/g)

    outputText = ""
    for line in templateLines
      matches = line.match /^#inject (.+)/
      if matches
        inject = matches[1]
        switch inject
          when 'title'
            outputText += "#{@title}\n"
          when 'list'
            for image in @images
              parsed = path.parse(image)
              outputText += "    <a href=\"#{constants.IMAGES_DIR}/#{parsed.base}\"></a>\n"
          else
            outputText += "<!-- #inject skipped '#{inject}' -->\n"
      else
        outputText += line
        outputText += "\n"

    fs.writeFileSync @indexFilename, outputText
    log.verbose "Wrote #{@indexFilename}"
    log.progress "Generated index for #{@title}"
    return true

class IndexGenerator
  constructor: (@dir) ->

module.exports =
  IndexGenerator: IndexGenerator
  ComicGenerator: ComicGenerator
