cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'
touch = require 'touch'
wrench = require 'wrench'
{ComicGenerator, IndexGenerator, MobileGenerator} = require './generators'
Unpacker = require './unpacker'

class Crackers
  constructor: ->

  error: (text) ->
    log.error text
    return false

  update: (args) ->
    # Pull member variables from args, calculate the rest
    @force = args.force
    @download = args.download
    @updateDir = path.resolve('.', args.dir)
    if not cfs.dirExists(@updateDir)
      return @error("'#{@updateDir}' is not an existing directory.")
    log.verbose "updateDir: #{@updateDir}"
    @rootDir = cfs.findParentContainingFilename(@updateDir, constants.ROOT_FILENAME)
    if not @rootDir
      @rootDir = @updateDir
      log.warning "crackers root not found (#{constants.ROOT_FILENAME} not detected in parents)."
    log.verbose "rootDir  : #{@rootDir}"

    cfs.touchRoot @rootDir

    # Unpack any cbr or cbz files that need unpacking in the update dir
    filesToUnpack = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/\.cb[rz]$/))
    for unpackFile in filesToUnpack
      parsed = path.parse(unpackFile)
      unpackDir = cfs.join(parsed.dir, parsed.name)
      log.verbose "Processing #{unpackFile} ..."
      @unpack(unpackFile, unpackDir, @force)

    # Regenerate index.html for all comics
    imageDirs = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/images$/))
    prevDir = ""
    for imageDir, i in imageDirs
      parsed = path.parse(imageDir)
      if parsed.dir
        comicDir = parsed.dir
        parent = path.parse(parsed.dir)
        nextDir = ""
        comicName = parent.name
        if i+1 < imageDirs.length
          nextParsed = path.parse(imageDirs[i+1])
          if nextParsed.dir
            nextParent = path.parse(nextParsed.dir)
            if nextParent.name and (parent.dir == nextParent.dir)
              nextDir = "../#{nextParent.name}"
        comicGenerator = new ComicGenerator(@rootDir, comicDir, prevDir, nextDir, @force)
        comicGenerator.generate()
        if (nextDir.length > 0) and (comicName.length > 0)
          # The comic we just generated had a nextDir, therefore the next comic should
          # have this comic as the prevdir
          prevDir = "../#{comicName}"
        else
          prevDir = ""

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
      indexGenerator = new IndexGenerator(@rootDir, indexDir, @force, @download)
      indexGenerator.generate()

    mobileGenerator = new MobileGenerator(@rootDir)
    mobileGenerator.generate()

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

  findArchives: (filenames) ->
    archives = []
    cbrRegex = /\.cb[rz]$/i
    for filename in filenames
      if not fs.existsSync(filename)
        log.warning "Ignoring nonexistent filename: #{filename}"
        continue
      stat = fs.statSync(filename)
      if stat.isFile()
        if filename.match(cbrRegex)
          archives.push filename
      else if stat.isDirectory()
        list = cfs.listDir(filename)
        for fn in list
          fn = path.resolve(filename, fn)
          if fn.match(cbrRegex)
            archives.push fn
      else
        log.warning "Ignoring unrecognized filename: #{filename}"
    return archives

  processTemplate: (template, name) ->
    keys = {}

    match = name.match(/^(\D*)(\d+)/)
    if match
      keys.name = match[1]
      keys.name = keys.name.replace(/[\. ]+$/, '')
      keys.issue = match[2]
    else
      return name

    output = template
    output = output.replace /\{([^\}]+)\}/g, (match, key) ->
      replacement = keys[key] ? ""
      pieces = key.split(/\./)
      if pieces.length > 1
        replacement = keys[pieces[0]] ? ""
        places = parseInt(pieces[1])
        if replacement.length < places
          replacement = "00000000000000000000000000000" + replacement
          replacement = replacement.substr(replacement.length - places)
      return replacement
    output = output.replace(/^[ \/]+/, '')
    output = output.replace(/[ \/]+$/, '')
    return output

  organize: (args) ->
    archives = @findArchives(args.filenames)
    if archives.length == 0
      log.warning "organize: Nothing to do!"
      return

    template = args.template
    if not template
      template = "{name}/{issue.3}"
    template = template.replace(/\\/g, '/')
    template = template.replace(/\/\//g, '/')
    template = template.replace(/\//g, path.sep)

    madeDir = {}
    mvCmd = "mv"
    mvCmd = "rename" if process.platform == 'win32'
    mkdirCmd = "mkdir -p"
    mkdirCmd = "mkdir" if process.platform == 'win32'
    for src in archives
      parsed = path.parse(src)
      # console.log parsed
      processed = @processTemplate(template, parsed.name)
      dst = cfs.join(parsed.dir, processed) + parsed.ext
      parsed = path.parse(dst)
      dstDir = parsed.dir
      if not madeDir[dstDir] and not cfs.dirExists(dstDir)
        madeDir[dstDir] = true
        if args.execute
          console.log " Mkdir: \"#{dstDir}\""
          wrench.mkdirSyncRecursive(dstDir)
        else
          console.log "#{mkdirCmd} \"#{dstDir}\""
      if src == dst
        if args.execute
          console.log "Skip  : \"#{src}\""
      else
        if args.execute
          console.log "Rename: \"#{src}\""
          console.log "    to: \"#{dst}\""
          fs.renameSync(src, dst)
        else
          console.log "#{mvCmd} \"#{src}\" \"#{dst}\""
    return

  cleanup: (args) ->
    archives = @findArchives(args.filenames)
    if archives.length == 0
      log.warning "cleanup: Nothing to do!"
      return

    cmd = "rm"
    cmd = "del" if process.platform == 'win32'
    for filename in archives
      if args.execute
        console.log "Removing: #{filename}"
        fs.unlinkSync(filename)
      else
        console.log "#{cmd} \"#{filename}\""
    return

module.exports = Crackers
