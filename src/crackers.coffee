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
      return @error("'#{@upadteDir}' is not an existing directory.")
    log.verbose "updateDir: #{@updateDir}"
    @rootDir = cfs.findParentContainingFilename(@updateDir, constants.ROOT_FILENAME)
    if not @rootDir
      @rootDir = @updateDir
      log.verbose "crackers root not found (#{constants.ROOT_FILENAME} not detected in parents)."
    log.verbose "rootDir  : #{@rootDir}"

    @rootFilename = path.join(@rootDir, constants.ROOT_FILENAME)
    touch.sync(@rootFilename)

    # Get a full list of all files/dirs inside of @updateDir
    updateFiles = cfs.listDir(@updateDir)

    # Unpack any cbr or cbz files that need unpacking in the update dir
    filesToUnpack = (path.resolve(@updateDir, file) for file in updateFiles when file.match(/\.cb[rz]$/))
    for unpackFile in filesToUnpack
      parsed = path.parse(unpackFile)
      unpackDir = path.join(parsed.dir, parsed.name)
      log.progress "Processing #{unpackFile} ..."
      @unpack(unpackFile, unpackDir)

    # All done!
    return true

  unpack: (file, dir, force = false) ->
    log.verbose "Unpacking #{file} into #{dir}"
    if not cfs.prepareComicDir(dir)
      return false

    indexFilename = path.join(dir, constants.INDEX_FILENAME)
    unpackRequired = force
    if cfs.newer(file, indexFilename)
      unpackRequired = true

    if unpackRequired
      unpacker = new Unpacker(file, dir)
      valid = unpacker.unpack()
      unpacker.cleanup()
      if not valid
        return false
    else
      log.progress "Unpack not required (#{file} older than #{indexFilename})"

    parsed = path.parse(dir)
    comicGenerator = new ComicGenerator(dir, parsed.name)
    comicGenerator.generate()

    return true

module.exports = Crackers
