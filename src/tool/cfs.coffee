# cracker file system

constants = require './constants'
fs = require 'fs'
path = require 'path'
log = require './log'
touch = require 'touch'

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
  return Math.floor(dirStats.mtime.getTime() / 1000)

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

cfs.ensureFileExists = (file) ->
  if fs.existsSync(file)
    return
  touch.sync(file)
  return

cfs.insideDir = (filename, dir) ->
  if filename.indexOf(dir) == 0
    return true
  return false

cfs.findArchive = (dir, comic) ->
  basename = path.join(dir, comic)
  if cfs.fileExists("#{basename}.cbr")
    return "#{comic}.cbr"
  if cfs.fileExists("#{basename}.cbt")
    return "#{comic}.cbt"
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
  return cfs.readdirSyncRecursive(dir)

cfs.listImages = (dir) ->
  list = cfs.readdirSyncRecursive(dir)
  images = (path.resolve(dir, file) for file in list when file.match(/\.(png|jpg|jpeg|webp)$/i))
  return images.sort()

cfs.gatherComics = (subDir, rootDir) ->
  subDir = subDir.replace("#{path.sep}$", "")
  if not rootDir?
    rootDir = subDir
  rootDir = rootDir.replace("#{path.sep}$", "")
  list = cfs.readdirSyncRecursive(subDir)
  comicDirs = (path.resolve(subDir, file).replace(/[\/\\]images$/, "") for file in list when file.match(/images$/i))
  comics = []
  for dir in comicDirs
    relativeDir = dir.substr(rootDir.length + 1)
    relativeDir = relativeDir.replace(/\\/g, "/")
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
    progress: ""
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

cfs.getProgressEndpoint = (dir) ->
  rootFilename = cfs.join(dir, constants.ROOT_FILENAME)
  if cfs.fileHasBytes(rootFilename)
    try
      rawJSON = fs.readFileSync(rootFilename)
      data = JSON.parse(rawJSON)
      if data.progress
        return data.progress
    catch

  return ""

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
    cfs.rmdirSyncRecursive(dir, true)
  return

cfs.newer = (amINewer, thanThisFile) ->
  if not fs.existsSync(amINewer)
    return true
  if not fs.existsSync(thanThisFile)
    return true

  amINewerStats = fs.statSync(amINewer)
  thanThisFileStats = fs.statSync(thanThisFile)
  return amINewerStats.mtime > thanThisFileStats.mtime

# Taken/adapted from deprecated 'wrench' module by Ryan McGrath
cfs.readdirSyncRecursive = (baseDir) ->
  baseDir = baseDir.replace(/\/$/, '')

  readdirSyncRecursive = (baseDir) ->
    files = []
    isDir = (fname) ->
      if fs.existsSync(path.join(baseDir, fname))
        return fs.statSync( path.join(baseDir, fname) ).isDirectory()
      return false
    prependBaseDir = (fname) ->
      return path.join(baseDir, fname)

    curFiles = fs.readdirSync(baseDir)
    nextDirs = curFiles.filter(isDir)
    curFiles = curFiles.map(prependBaseDir)

    files = files.concat(curFiles)

    while nextDirs.length > 0
      files = files.concat( readdirSyncRecursive(path.join(baseDir, nextDirs.shift())) )

    return files

  # convert absolute paths to relative
  fileList = readdirSyncRecursive(baseDir).map (val) ->
    return path.relative(baseDir, val)

  return fileList

# Taken/adapted from deprecated 'wrench' module by Ryan McGrath
cfs.rmdirSyncRecursive = (dir, failSilent) ->
  isWindows = !!process.platform.match(/^win/)

  try
    files = fs.readdirSync(dir)
  catch err
    return if failSilent
    throw new Error(err.message)

  # Loop through and delete everything in the sub-tree after checking it
  for file in files
    file = path.join(dir, file)
    currFile = fs.lstatSync(file)

    if currFile.isDirectory()
      # Recursive function back to the beginning
      cfs.rmdirSyncRecursive(file)
    else if currFile.isSymbolicLink()
      # Unlink symlinks
      if isWindows
        fs.chmodSync(file, 666) # Windows needs this unless joyent/node#3006 is resolved..

      fs.unlinkSync(file)
    else
      # Assume it's a file - perhaps a try/catch belongs here?
      if isWindows
        fs.chmodSync(file, 666) # Windows needs this unless joyent/node#3006 is resolved..

      fs.unlinkSync(file)

  # Now that we know everything in the sub-tree has been deleted, we can delete the main directory. Huzzah for the shopkeep.
  return fs.rmdirSync(dir)

# Taken/adapted from deprecated 'wrench' module by Ryan McGrath
cfs.mkdirSyncRecursive = (dir, mode) ->
  dir = path.normalize(dir)

  try
    fs.mkdirSync(dir, mode)
  catch err
    if err.code == "ENOENT"
      slashIdx = dir.lastIndexOf(path.sep)

      if slashIdx > 0
        parentDir = dir.substring(0, slashIdx)
        cfs.mkdirSyncRecursive(parentDir, mode)
        cfs.mkdirSyncRecursive(dir, mode)
      else
        throw err

    else if err.code == "EEXIST"
      return
    else
      throw err

  return

# Taken/adapted from deprecated 'wrench' module by Ryan McGrath
cfs.chmodSyncRecursive = (sourceDir, filemode) ->
  files = fs.readdirSync(sourceDir)

  for file in files
    currFile = fs.lstatSync(path.join(sourceDir, file))

    if currFile.isDirectory()
      #  ...and recursion this thing right on back.
      cfs.chmodSyncRecursive(path.join(sourceDir, file), filemode)
    else
      # At this point, we've hit a file actually worth copying... so copy it on over.
      fs.chmod(path.join(sourceDir, file), filemode)

  # Finally, chmod the parent directory
  return fs.chmod(sourceDir, filemode)

module.exports = cfs
