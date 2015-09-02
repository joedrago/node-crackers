cfs = require './cfs'
constants = require './constants'
log = require './log'
path = require 'path'
touch = require 'touch'
{ComicGenerator, IndexGenerator} = require './generators'
Unpacker = require './unpacker'

class Crackers
  constructor: ->

  error: (text) ->
    log.error text
    return false

  update: (args) ->
    # Pull member variables from args, calculate the rest
    @updateDir = path.resolve('.', args.dir)
    if not cfs.dirExists(@updateDir)
      return @error("'#{@updateDir}' is not an existing directory.")
    log.verbose "updateDir: #{@updateDir}"
    @rootDir = cfs.findParentContainingFilename(@updateDir, constants.ROOT_FILENAME)
    if not @rootDir
      @rootDir = @updateDir
      log.verbose "crackers root not found (#{constants.ROOT_FILENAME} not detected in parents)."
    log.verbose "rootDir  : #{@rootDir}"

    @rootFilename = cfs.join(@rootDir, constants.ROOT_FILENAME)
    touch.sync(@rootFilename)

    # Unpack any cbr or cbz files that need unpacking in the update dir
    filesToUnpack = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/\.cb[rz]$/))
    for unpackFile in filesToUnpack
      parsed = path.parse(unpackFile)
      unpackDir = cfs.join(parsed.dir, parsed.name)
      log.verbose "Processing #{unpackFile} ..."
      @unpack(unpackFile, unpackDir)

    # Regenerate index.html for all comics
    imageDirs = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/images$/))
    for imageDir in imageDirs
      parsed = path.parse(imageDir)
      if parsed.dir
        comicDir = parsed.dir
        parsed = path.parse(comicDir)
        comicGenerator = new ComicGenerator(@rootDir, comicDir, parsed.name)
        comicGenerator.generate()

    # All done!
    return true

  unpack: (file, dir, force = false) ->
    if not cfs.prepareComicDir(dir)
      return false

    indexFilename = cfs.join(dir, constants.INDEX_FILENAME)
    unpackRequired = force
    if cfs.newer(file, indexFilename)
      unpackRequired = true

    if unpackRequired
      log.progress "Unpacking #{file} into #{dir}"
      unpacker = new Unpacker(file, dir)
      valid = unpacker.unpack()
      unpacker.cleanup()
      if not valid
        return false
    else
      log.verbose "Unpack not required: (#{file} older than #{indexFilename})"

    return true

module.exports = Crackers
