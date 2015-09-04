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
    @force = args.force
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
      @unpack(unpackFile, unpackDir, @force)

    # Regenerate index.html for all comics
    imageDirs = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/images$/))
    for imageDir, i in imageDirs
      parsed = path.parse(imageDir)
      if parsed.dir
        comicDir = parsed.dir
        parent = path.parse(parsed.dir)
        nextDir = ""
        if i+1 < imageDirs.length
          nextParsed = path.parse(imageDirs[i+1])
          if nextParsed.dir
            nextParent = path.parse(nextParsed.dir)
            if nextParent.name and (parent.dir == nextParent.dir)
              nextDir = "../#{nextParent.name}"
        comicGenerator = new ComicGenerator(@rootDir, comicDir, nextDir, @force)
        comicGenerator.generate()

    # Find directories that need indexing
    indexDirSeen = {}
    for imageDir in imageDirs
      imageDirPieces = imageDir.split(path.sep)
      imageDirPieces.pop() # pop "images"
      imageDirPieces.pop() # pop comic dir
      while imageDirPieces.length > 1
        indexDir = cfs.join.apply(null, imageDirPieces)
        indexDirSeen[indexDir] = true
        break if indexDir == @rootDir
        imageDirPieces.pop()

    # regenerate all indices
    indexDirs = Object.keys(indexDirSeen).sort().reverse()
    for indexDir in indexDirs
      indexGenerator = new IndexGenerator(@rootDir, indexDir, @force)
      indexGenerator.generate()

    # All done!
    return true

  unpack: (file, dir, force) ->
    if not cfs.prepareComicDir(dir)
      return false

    indexFilename = cfs.join(dir, constants.INDEX_FILENAME)
    unpackRequired = force.unpack
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
