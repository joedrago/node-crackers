cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'

class ManifestGenerator
  constructor: (@rootDir) ->
    @manifestFilename = cfs.join(@rootDir, constants.MANIFEST_FILENAME)

  generate: ->
    comics = cfs.gatherComics(@rootDir)

    children = {}
    issues = {}
    flat = []
    for comic in comics
      metadata = cfs.readMetadata(comic.dir)
      parsed = path.parse(comic.relativeDir)
      indexDir = parsed.dir

      flat.push {
        dir: comic.relativeDir
        pages: metadata.pages
      }

      dir = comic.relativeDir
      atLeaf = true
      loop
        parsed = path.parse(dir)
        indexDir = parsed.dir ? ""

        if not children.hasOwnProperty(indexDir)
          children[indexDir] = {}
        if atLeaf
          children[indexDir][comic.relativeDir] = {
            type: 'issue'
            dir: comic.relativeDir
            pages: metadata.pages
          }
        else
          children[indexDir][dir] = {
            type: 'index'
            dir: dir
          }
        atLeaf = false

        if not issues.hasOwnProperty(indexDir)
          issues[indexDir] = []
        issues[indexDir].push {
          dir: comic.relativeDir
          pages: metadata.pages
        }
        dir = indexDir

        break if indexDir.length < 1

    newchildren = {}
    for indexDir,indexlist of children
      list = []
      keys = Object.keys(indexlist)
      for k in keys
        list.push indexlist[k]
      newchildren[indexDir] = list
    children = newchildren

    manifest = 
      issues: issues
      children: children
      flat: flat
    fs.writeFileSync @manifestFilename, JSON.stringify(manifest, null, 2)

module.exports = ManifestGenerator
