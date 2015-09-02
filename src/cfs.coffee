# cracker file system

fs = require 'fs'
path = require 'path'
log = require './log'
wrench = require 'wrench'

cfs = {}

cfs.dirExists = (dir) ->
  if not fs.existsSync(dir)
    return false
  stats = fs.statSync(dir)
  if stats.isDirectory()
    return true
  return false

cfs.fileExists = (dir) ->
  if not fs.existsSync(dir)
    return false
  stats = fs.statSync(dir)
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
    testPath = path.join.apply(null, testPieces)
    found = cfs.fileExists(testPath)
    # log.verbose "checking path #{testPath} (#{found})"
    if found
      return path.join.apply(null, dirPieces)
    dirPieces.pop()

  return false

cfs.listDir = (dir) ->
  return wrench.readdirSyncRecursive(dir)

cfs.listImages = (dir) ->
  list = wrench.readdirSyncRecursive(dir)
  images = (path.resolve(dir, file) for file in list when file.match(/\.(png|jpg|jpeg)$/i))
  return images.sort()

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
