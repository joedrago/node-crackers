fs = require 'fs'
cfs = require './cfs'
constants = require './constants'
exec = require './exec'
log = require './log'
path = require 'path'
which = require 'which'

class Unpacker
  constructor: (@archive, @dir) ->
    @detectFormat()

    now = String(Math.floor(new Date() / 1000))
    @tempDir = cfs.join(@dir, "#{constants.TEMP_UNPACK_DIR}.#{now}")
    @imagesDir = cfs.join(@dir, constants.IMAGES_DIR)
    @deadImagesDir = "#{@imagesDir}.#{now}"

    @valid = false

  cleanup: ->
    cfs.cleanupDir(@tempDir)
    cfs.cleanupDir(@deadImagesDir)
    if not @valid
      cfs.cleanupDir(@imagesDir)

  readHeader: ->
    fd = fs.openSync(@archive, 'r')
    buffer = new Buffer(2)
    bytesRead = fs.readSync(fd, buffer, 0, 2, 0)
    fs.closeSync(fd)
    if bytesRead == 2
      return buffer.toString()
    return false

  detectFormat: ->
    @type = 'cbr'
    if @archive.match(/cbz$/)
      @type = 'cbz'
    header = @readHeader()
    if header
      switch header
        when 'Ra' then @type = 'cbr'
        when 'PK' then @type = 'cbz'
    log.verbose "Detected format for #{@archive}: #{@type}"

  unpack: ->
    log.verbose "Unpacker: type #{@type} #{@archive} -> #{@dir}"

    # prepare temp dir
    log.verbose "Unpacker: @tempDir #{@tempDir}"
    if not cfs.prepareDir(@tempDir)
      log.error "Could not create temp dir for unpacking"
      return false

    # unpack to temp dir
    if @type == 'cbr'
      cmd = 'unrar'
      args = ['x', @archive]
    else
      cmd = 'unzip'
      args = [@archive]
    exec(cmd, args, @tempDir)

    # Prepare images directory
    if fs.existsSync(@imagesDir)
      # TODO: delete instead? scarrrry
      log.verbose "moving old images dir #{@imagesDir} to #{@deadImagesDir}"
      fs.renameSync(@imagesDir, @deadImagesDir)
    if not cfs.prepareDir(@imagesDir)
      log.error "Could not create images dir"
      return false

    images = cfs.listImages(@tempDir)
    if not images.length
      return false

    for image in images
      parsed = path.parse(image)
      finalImagePath = cfs.join(@imagesDir, parsed.base)
      fs.renameSync(image, finalImagePath)

    @valid = true
    return true

module.exports = Unpacker
