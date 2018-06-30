cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
path = require 'path'

class ManifestGenerator
  constructor: (@rootDir) ->

  generate: ->
    comics = cfs.gatherComics(@rootDir)

    children = {}
    issues = {}
    exists = {}
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
            type: 'comic'
            dir: comic.relativeDir
            pages: metadata.pages
            timestamp: comic.timestamp
          }
          exists[comic.relativeDir] = true
        else
          indexMetadata = cfs.readMetadata(path.join(@rootDir, dir))
          children[indexDir][dir] = {
            type: 'index'
            dir: dir
            recent: indexMetadata.recent
            count: indexMetadata.count
            timestamp: indexMetadata.timestamp
            first: indexMetadata.first
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

    serverManifest =
      issues: issues
      children: children
      flat: flat
      exists: exists
    fs.writeFileSync cfs.join(@rootDir, constants.MANIFEST_SERVER_FILENAME), JSON.stringify(serverManifest, null, 2)

    clientManifest =
      children: children
      exists: exists
    fs.writeFileSync cfs.join(@rootDir, constants.MANIFEST_CLIENT_FILENAME), JSON.stringify(clientManifest, null, 2)

module.exports = ManifestGenerator
