cfs = require './cfs'
constants = require './constants'
exec = require './exec'
fs = require 'fs'
log = require './log'
path = require 'path'

ComicGenerator = require './ComicGenerator'
RootGenerator = require './RootGenerator'
SubdirGenerator = require './SubdirGenerator'
Unpacker = require './Unpacker'

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
    log.verbose "updateDir  : #{@updateDir}"
    @rootDir = cfs.findParentContainingFilename(@updateDir, constants.ROOT_FILENAME)
    if not @rootDir
      @rootDir = @updateDir
      log.warning "crackers root not found (#{constants.ROOT_FILENAME} not detected in parents)."
    log.verbose "rootDir    : #{@rootDir}"
    @archivesDir = path.join(@rootDir, constants.ARCHIVES_DIR)
    log.verbose "archivesDir: #{@archivesDir}"

    cfs.touchRoot @rootDir
    cfs.prepareDir(@archivesDir)

    # Unpack any cbr, cbt, or cbz files that need unpacking in the update dir
    filesToUnpack = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/\.cb[rtz]$/))
    for unpackFile in filesToUnpack
      if cfs.insideDir(unpackFile, @archivesDir)
        log.verbose "Skipping archive #{unpackFile} ..."
        continue
      parsed = path.parse(unpackFile)
      unpackDir = cfs.join(parsed.dir, parsed.name)
      log.verbose "Processing #{unpackFile} ..."
      @unpack(unpackFile, unpackDir, @force)

    # regenerate all comic metadata/covers
    imageDirs = (path.resolve(@updateDir, file) for file in cfs.listDir(@updateDir) when file.match(/images$/))
    prevDir = ""
    sawOneComic = false
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
              absoluteNextDir = path.resolve(comicDir, "../#{nextParent.name}")
              nextDir = path.relative(@rootDir, absoluteNextDir).replace(/\\/g, "/")
        comicGenerator = new ComicGenerator(@rootDir, comicDir, prevDir, nextDir, @force)
        comicGenerator.generate()
        sawOneComic = true
        if (nextDir.length > 0) and (comicName.length > 0)
          # The comic we just generated had a nextDir, therefore the next comic should
          # have this comic as the prevdir
          relativeComicDir = path.relative(@rootDir, comicDir)
          relativeComicDir = '.' if relativeComicDir.length == 0
          relativeComicDir = relativeComicDir.replace(/\\/g, "/")
          prevDir = relativeComicDir
        else
          prevDir = ""

    # Find subdirs containing comics
    subdirSeen = {}
    for imageDir in imageDirs
      imageDirPieces = imageDir.split(path.sep)
      imageDirPieces.pop() # pop "images"
      imageDirPieces.pop() # pop comic dir
      while imageDirPieces.length > 1
        subdir = cfs.join.apply(null, imageDirPieces)
        break if subdir == @rootDir
        subdirSeen[subdir] = true
        imageDirPieces.pop()

    # regenerate all subdir metadata/covers
    subdirs = Object.keys(subdirSeen).sort().reverse()
    for subdir in subdirs
      subdirGenerator = new SubdirGenerator(@rootDir, subdir, @force, @download)
      subdirGenerator.generate()

    rootGenerator = new RootGenerator(@rootDir, @force, @download)
    rootGenerator.generate()

    if not sawOneComic
      @error "No comics found. Please add at least one .cbr, .cbt, .cbz to a subdirectory and run this command again."

    # All done!
    return true

  unpack: (file, dir, force) ->
    if not cfs.prepareComicDir(dir)
      return false

    metaFilename = cfs.join(dir, constants.META_FILENAME)
    unpackRequired = force.unpack
    if cfs.newer(file, metaFilename)
      unpackRequired = true

    if unpackRequired
      log.progress "Unpacking #{file} into #{dir}"
      unpacker = new Unpacker(file, dir)
      valid = unpacker.unpack()
      unpacker.cleanup()
      if not valid
        return false
    else
      log.verbose "Unpack not required: (#{file} older than #{metaFilename})"

    return true

  findArchives: (filenames) ->
    archives = []
    cbrRegex = /\.cb[rtz]$/i
    for filename in filenames
      if not fs.existsSync(filename)
        log.warning "Ignoring nonexistent filename: #{filename}"
        continue
      stat = fs.statSync(filename)
      if stat.isFile()
        if filename.match(cbrRegex)
          archives.push {
            abs: filename
            rel: null
          }
      else if stat.isDirectory()
        list = cfs.listDir(filename)
        for fn in list
          fn = path.resolve(filename, fn)
          if fn.match(cbrRegex)
            rel = path.relative(filename, fn)
            archives.push {
              abs: fn
              rel: rel
            }
      else
        log.warning "Ignoring unrecognized filename: #{filename}"
    return archives

  processTemplate: (template, name, skipCount) ->
    keys = {}

    issueRegex = switch skipCount
      when 3 then /^(\D*\d+\D+\d+\D+\d+\D+)(\d+)/
      when 2 then /^(\D*\d+\D+\d+\D+)(\d+)/
      when 1 then /^(\D*\d+\D+)(\d+)/
      else        /^(\D*)(\d+)/

    match = name.match(issueRegex)
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
    mergeDst = null
    if args.hasOwnProperty('dst')
      mergeDst = args.dst
    archives = @findArchives(args.filenames)
    if archives.length == 0
      log.warning "organize: Nothing to do!"
      return

    skip = args.skip ? 0

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
    for archive in archives
      # src is always just the archive's absolute path.
      src = archive.abs

      # calculate dst, based on whether or not we're merging, and
      # how we found it (via dir listing or directly referenced).
      if mergeDst == null
        # regular organize call. Organize in-place.
        parsed = path.parse(src)
        processed = @processTemplate(template, parsed.name, skip)
        if parsed.dir.length == 0
          parsed.dir = '.'
        dst = cfs.join(parsed.dir, processed) + parsed.ext
      else
        # merge call. Do template processing if a filename was directly
        # referenced (indicated by the relative path being absent).
        if archive.rel == null
          parsed = path.parse(src)
          processed = @processTemplate(template, parsed.name, skip)
          dst = cfs.join(mergeDst, processed) + parsed.ext
        else
          dst = path.resolve(mergeDst, archive.rel)

      parsed = path.parse(dst)
      dstDir = parsed.dir
      if not madeDir[dstDir] and not cfs.dirExists(dstDir)
        madeDir[dstDir] = true
        if args.execute
          console.log " Mkdir: \"#{dstDir}\""
          cfs.mkdirSyncRecursive(dstDir)
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
    archivedCount = 0
    processedCount = 0

    cmd = "rm"
    cmd = "del" if process.platform == 'win32'
    for archive in archives
      filename = archive.abs

      parsed = path.parse(filename)
      rootDir = cfs.findParentContainingFilename(filename, constants.ROOT_FILENAME)
      if not rootDir
        log.warning "Skipping #{filename}, not in a crackers root"
        continue
      archivesDir = cfs.join(rootDir, constants.ARCHIVES_DIR)
      if cfs.insideDir(filename, archivesDir)
        archivedCount += 1
        log.verbose "Skipping archived comic: #{filename}"
        continue

      if args.execute
        console.log "Removing: #{filename}"
        fs.unlinkSync(filename)
      else
        console.log "#{cmd} \"#{filename}\""
      processedCount += 1

    if processedCount == 0
      log.warning "cleanup: Nothing to do! (skipped #{archivedCount} archived comics)"
      return
    return

  archiveComic: (comicDir, archiveFilename) ->
    if cfs.fileExists(archiveFilename)
      fs.unlinkSync(archiveFilename)
    args = ['-r0', archiveFilename, 'images']
    exec('zip', args, comicDir)

  archive: (args) ->
    for filename in args.filenames
      rootDir = cfs.findParentContainingFilename(filename, constants.ROOT_FILENAME)
      if not rootDir
        log.warning "Skipping #{filename}, not in a crackers root"
        continue
      comics = cfs.gatherComics(filename, rootDir)
      for comic in comics
        archiveFilename = cfs.join(rootDir, constants.ARCHIVES_DIR, "#{comic.relativeDir}.cbz")
        parsed = path.parse archiveFilename
        archiveDir = parsed.dir
        cfs.mkdirSyncRecursive(archiveDir)
        if not cfs.prepareDir(archiveDir)
          continue
        if args.force or cfs.newer(comic.dir, archiveFilename)
          log.progress "[pack] #{comic.dir} -> #{archiveFilename}"
          @archiveComic(comic.dir, archiveFilename)
        else
          log.progress "[skip] #{comic.dir} -> #{archiveFilename}"
          continue

    return

module.exports = Crackers
