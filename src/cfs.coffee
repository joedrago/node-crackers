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

cfs.fileExists = (file) ->
  if not fs.existsSync(file)
    return false
  stats = fs.statSync(file)
  if stats.isFile()
    return true
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

cfs.gatherIndex = (dir) ->
  indexList = []
  fileList = fs.readdirSync(dir).sort()
  for file in fileList
    resolvedPath = path.resolve(dir, file)
    metadata = cfs.readMetadata(resolvedPath)
    continue if not metadata
    indexList.push {
      path: file
      type: metadata.type
      count: metadata.count
      cover: metadata.cover
    }
  indexList.sort (a, b) ->
    if a.type == b.type
      if a.path == b.path
        return 0
      if a.path > b.path
        return 1
      return -1
    if a.type > b.type
      return 1
    return -1
  return indexList

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

cfs.writeMetadata = (dir, metadata) ->
  @metaFilename = cfs.join(dir, constants.META_FILENAME)
  json = JSON.stringify(metadata, null, 2)
  log.verbose "writeMetadata (#{dir}): #{metadata}"
  fs.writeFileSync @metaFilename, json

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
  return amINewerStats.mtime > thanThisFile.mtime

module.exports = cfs
