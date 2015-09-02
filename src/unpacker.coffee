fs = require 'fs'
cfs = require './cfs'
constants = require './constants'
exec = require './exec'
log = require './log'
path = require 'path'
sizeOf = require 'image-size'
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

    # -----------------------------------------------------------------------------------
    # Spam detection -- looks for images that are oddly sized and small

    dimensionMap = {}
    widthMap = {}
    heightMap = {}
    validDimsCount = 0
    for image in images
      dimensions = sizeOf(image)
      dimensionMap[image] = dimensions
      if (dimensions.width < 10) or (dimensions.width < 10)
        continue
      dimensions.width = Math.round(dimensions.width / 100) * 100
      dimensions.height = Math.round(dimensions.height / 100) * 100
      if not widthMap[dimensions.width]
        widthMap[dimensions.width] = 1
      else
        widthMap[dimensions.width] += 1
      if not heightMap[dimensions.height]
        heightMap[dimensions.height] = 1
      else
        heightMap[dimensions.height] += 1
      validDimsCount += 1
      # log.verbose "dimensions for #{image}: #{JSON.stringify(dimensions, null, 2)}"

    if validDimsCount > 0
      widths = Object.keys(widthMap).sort (a, b) ->
        return  0 if widthMap[a] == widthMap[b]
        return -1 if widthMap[a] > widthMap[b]
        return 1
      heights = Object.keys(heightMap).sort (a, b) ->
        return  0 if heightMap[a] == heightMap[b]
        return -1 if heightMap[a] > heightMap[b]
        return 1
      log.verbose "widthMap", widthMap
      log.verbose "heightMap", heightMap
      mostCommonWidth = widths[0]
      mostCommonHeight = heights[0]

    maxToleranceW = mostCommonWidth  * constants.SPAM_SIZE_TOLERANCE
    maxToleranceH = mostCommonHeight * constants.SPAM_SIZE_TOLERANCE

    # -----------------------------------------------------------------------------------

    for image in images
      # if these are negative, the image is larger than the typical size. Let it through as it is probably cover art
      dims = dimensionMap[image]
      toleranceW = mostCommonWidth - dims.width
      toleranceH = mostCommonHeight - dims.height
      if (toleranceW > maxToleranceW) or (toleranceH > maxToleranceH)
        # See if it is a proper image that is simply rotated
        rotToleranceW = mostCommonHeight - dims.width
        rotToleranceH = mostCommonWidth - dims.height
        if (rotToleranceW > maxToleranceW) or (rotToleranceH > maxToleranceH)
          log.verbose "Spam detected: '#{image}' is #{dims.width}x#{dims.height}, not close enough to #{mostCommonWidth}x#{mostCommonHeight}"
          continue

      # Add the image to the /images dir
      parsed = path.parse(image)
      finalImagePath = cfs.join(@imagesDir, parsed.base)
      fs.renameSync(image, finalImagePath)

    @valid = true
    return true

module.exports = Unpacker
