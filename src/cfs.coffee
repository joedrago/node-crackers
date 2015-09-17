# cracker file system

constants = require './constants'
fs = require 'fs'
path = require 'path'
log = require './log'
wrench = require 'wrench'

cfs = {}

cfs.join = ->
  result = path.join.apply(null, arguments)
  # work around stupid lack of symmetry between path.join and split(sep)
  if arguments.length > 0 and arguments[0] == ''
    result = "/#{result}"
  return result

cfs.dirExists = (dir) ->
  if not fs.existsSync(dir)
    return false
  stats = fs.statSync(dir)
  if stats.isDirectory()
    return true
  return false

cfs.dirTime = (dir) ->
  dirStats = fs.statSync(dir)
  return 0 if not dirStats?
  return Math.floor(dirStats.birthtime.getTime() / 1000)

cfs.fileExists = (file) ->
  if not fs.existsSync(file)
    return false
  stats = fs.statSync(file)
  if stats.isFile()
    return true
  return false

cfs.fileHasBytes = (file) ->
  if not fs.existsSync(file)
    return false
  stats = fs.statSync(file)
  if stats.isFile()
    return (stats.size > 0)
  return false

cfs.findArchive = (dir, comic) ->
  basename = path.join(dir, comic)
  if cfs.fileExists("#{basename}.cbr")
    return "#{comic}.cbr"
  if cfs.fileExists("#{basename}.cbz")
    return "#{comic}.cbz"
  return false

cfs.findParentContainingFilename = (startDir, filename) ->
  startDir = path.resolve('.', startDir)
  dirPieces = startDir.split(path.sep)
  loop
    if not dirPieces.length
      return false
    testPieces = dirPieces.slice()
    testPieces.push(filename)
    testPath = cfs.join.apply(null, testPieces)
    found = cfs.fileExists(testPath)
    # log.verbose "checking path #{testPath} (#{found})"
    if found
      return cfs.join.apply(null, dirPieces)
    dirPieces.pop()

  return false

cfs.listDir = (dir) ->
  return wrench.readdirSyncRecursive(dir)

cfs.listImages = (dir) ->
  list = wrench.readdirSyncRecursive(dir)
  images = (path.resolve(dir, file) for file in list when file.match(/\.(png|jpg|jpeg)$/i))
  return images.sort()

cfs.gatherComics = (rootDir) ->
  rootDir = rootDir.replace("#{path.sep}$", "")
  list = wrench.readdirSyncRecursive(rootDir)
  comicDirs = (path.resolve(rootDir, file).replace(/\/images$/, "") for file in list when file.match(/images$/i))
  comics = []
  for dir in comicDirs
    relativeDir = dir.substr(rootDir.length + 1)
    metadata = cfs.readMetadata(dir)
    if metadata
      metadata.dir = dir
      metadata.relativeDir = relativeDir
      comics.push metadata
  return comics

cfs.gatherMetadata = (dir) ->
  mdList = []
  fileList = fs.readdirSync(dir).sort()
  for file in fileList
    resolvedPath = path.resolve(dir, file)
    metadata = cfs.readMetadata(resolvedPath)
    continue if not metadata
    metadata.path = file
    mdList.push metadata
  mdList.sort (a, b) ->
    #if a.type == b.type
      if a.path == b.path
        return 0
      if a.path > b.path
        return 1
      return -1
    #if a.type > b.type
    #  return 1
    #return -1
  return mdList

cfs.readMetadata = (dir) ->
  metaFilename = cfs.join(dir, constants.META_FILENAME)
  if not fs.existsSync(metaFilename)
    return false
  rawText = fs.readFileSync(metaFilename)
  if not rawText
    return false
  try
    metadata = JSON.parse(rawText)
  catch
    metadata = false
  return metadata

cfs.touchRoot = (dir) ->
  rootFilename = cfs.join(dir, constants.ROOT_FILENAME)
  return if cfs.fileHasBytes(rootFilename)
  rootinfo = {
    title: constants.DEFAULT_TITLE
  }
  json = JSON.stringify(rootinfo, null, 2)
  fs.writeFileSync rootFilename, json

cfs.getRootTitle = (dir) ->
  rootFilename = cfs.join(dir, constants.ROOT_FILENAME)
  if cfs.fileHasBytes(rootFilename)
    try
      rawJSON = fs.readFileSync(rootFilename)
      data = JSON.parse(rawJSON)
      if data.title
        return data.title
    catch

  return constants.DEFAULT_TITLE

cfs.writeMetadata = (dir, metadata) ->
  metaFilename = cfs.join(dir, constants.META_FILENAME)
  json = JSON.stringify(metadata, null, 2)
  # log.verbose "writeMetadata (#{dir}): #{JSON.stringify(metadata, null, 2)}"
  fs.writeFileSync metaFilename, json

cfs.removeMetadata = (dir, metadata) ->
  metaFilename = cfs.join(dir, constants.META_FILENAME)
  # log.verbose "removeMetadata (#{dir})"
  fs.unlinkSync metaFilename

cfs.copyFile = (src, dst) ->
  log.verbose "copyFile #{src} -> #{dst}"
  fs.writeFileSync(dst, fs.readFileSync(src));

cfs.prepareDir = (dir) ->
  # Ensure the directory exists, and is a directory
  if not fs.existsSync(dir)
    fs.mkdirSync(dir)
  if not fs.existsSync(dir)
    log.error "Cannot create directory #{dir}, mkdir failed"
    return false
  stats = fs.statSync(dir)
  if not stats.isDirectory()
    log.error "Cannot create directory #{dir}, file exists (not a dir)"
    return false
  return true

cfs.prepareComicDir = (dir) ->
  if not cfs.prepareDir(dir)
    return false

  log.verbose "Comic directory prepared: #{dir}"
  return true

cfs.cleanupDir = (dir) ->
  if fs.existsSync(dir)
    log.verbose "Cleaning up #{dir}"
    wrench.rmdirSyncRecursive(dir, true)
  return

cfs.newer = (amINewer, thanThisFile) ->
  if not fs.existsSync(amINewer)
    return true
  if not fs.existsSync(thanThisFile)
    return true

  amINewerStats = fs.statSync(amINewer)
  thanThisFileStats = fs.statSync(thanThisFile)
  return amINewerStats.mtime > thanThisFileStats.mtime

module.exports = cfs
