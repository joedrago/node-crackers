fs = require 'fs'
cfs = require './cfs'
constants = require './constants'
log = require './log'
path = require 'path'
{spawnSync} = require 'child_process'
which = require 'which'

class Unpacker
  constructor: (@archive, @dir) ->
    @type = 'cbr'
    if @archive.match(/cbz$/)
      @type = 'cbz'

    @unzipCmd = null
    @unrarCmd = null
    if process.platform == 'win32'
      @unzipCmd = path.resolve(__dirname, "../wbin/unzip.exe")
      @unrarCmd = path.resolve(__dirname, "../wbin/unrar.exe")
    else
      try
        @unzipCmd = which.sync('unzip')
      catch
      try
        @unrarCmd = which.sync('unrar')
      catch

    if not @unzipCmd
      log.error "crackers requires unzip to be installed."
    if not @unrarCmd
      log.error "crackers requires unrar to be installed."

    log.verbose "unzip: #{@unzipCmd}"
    log.verbose "unrar: #{@unrarCmd}"

    now = String(Math.floor(new Date() / 1000))
    @tempDir = path.join(@dir, "#{constants.TEMP_UNPACK_DIR}.#{now}")
    @imagesDir = path.join(@dir, constants.IMAGES_DIR)
    @deadImagesDir = "#{@imagesDir}.#{now}"

    @valid = false

  cleanup: ->
    cfs.cleanupDir(@tempDir)
    cfs.cleanupDir(@deadImagesDir)
    if not @valid
      cfs.cleanupDir(@imagesDir)

  unpack: ->
    if not @unzipCmd or not @unrarCmd
      return false

    log.verbose "Unpacker: Type #{@type} #{@archive} -> #{@dir}"

    # prepare temp dir
    log.verbose "Unpacker: @tempDir #{@tempDir}"
    if not cfs.prepareDir(@tempDir)
      log.error "Could not create temp dir for unpacking"
      return false

    # unpack to temp dir
    if @type == 'cbr'
      cmd = @unrarCmd
      args = ['x', @archive]
    else
      cmd = @unzipCmd
      args = [@archive]
    log.verbose "Unpacker: executing cmd '#{cmd}', args #{args}"
    spawnSync(cmd, args, {
      cwd: @tempDir
      stdio: 'ignore'
    })

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
      finalImagePath = path.join(@imagesDir, parsed.base)
      fs.renameSync(image, finalImagePath)

    @valid = true
    return true

module.exports = Unpacker
