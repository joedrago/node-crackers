cfs = require './cfs'
constants = require './constants'
moment = require 'moment'
path = require 'path'

BUCKET_WINDOW = 24 * 60 * 60

formatDate = (ts) ->
  return moment(ts * 1000).format('YYYYMMDD')

formatPrettyDate = (ts) ->
  return moment(ts * 1000).format('MMMM Do, YYYY')

sortByRelativeDir = (a, b) ->
  return -1 if a.relativeDir < b.relativeDir
  return  1 if a.relativeDir > b.relativeDir
  return  0

sortByTimestampDescending = (a, b) ->
  return  1 if a.timestamp < b.timestamp
  return -1 if a.timestamp > b.timestamp
  return  0

class UpdatesGenerator
  constructor: (@rootDir) ->
    @comics = cfs.gatherComics(@rootDir)
    @comics.sort(sortByTimestampDescending)

    timeBuckets = []
    bucket = null
    for comic in @comics
      ts = @roundTimestamp(comic.timestamp)
      if bucket
        if bucket.start == ts
          bucket.list.push comic
        else
          bucket = null
      if not bucket
        bucket =
          start: ts
          list: [ comic ]
        timeBuckets.push bucket

    @updates = []
    for bucket in timeBuckets
      update =
        list: []
        pdate: formatPrettyDate(bucket.start)
        date: formatDate(bucket.start)
      @updates.push update

      bucket.list.sort(sortByRelativeDir)
      seriesCover = null
      seriesDir = null
      startDir = null
      startIssue = 0
      endIssue = 0
      for comic in bucket.list
        parsed = path.parse(comic.relativeDir)
        issue = parseInt(parsed.name)
        # if the issue name isn't a simple number, or it is a new dir, or if it isnt the next issue...
        if (issue == NaN) or (startDir != parsed.dir) or (issue != endIssue + 1)
          # Found a series discontinuity. Dump whatever is currently in the pipeline
          # and start a new series.
          if startDir and (startIssue > 0) and (endIssue > 0)
            dir = startDir
            action = 'browse'
            if startIssue == endIssue
              dir = seriesDir
              action = 'comic'
            update.list.push {
              action: action
              dir: dir
              title: startDir
              start: startIssue
              end: endIssue
              cover: seriesCover
            }
            startDir = null
            seriesCover = null
          if issue > 0
            startDir = parsed.dir
            startIssue = endIssue = issue
            seriesCover = "#{comic.relativeDir}/#{constants.COVER_FILENAME}"
            seriesDir = comic.relativeDir
          else
            update.list.push {
              action: 'comic'
              dir: comic.relativeDir
              title: comic.relativeDir
              cover: "#{comic.relativeDir}/#{constants.COVER_FILENAME}"
            }
        else
          endIssue = issue

      if startDir and (startIssue > 0) and (endIssue > 0)
        dir = startDir
        action = 'browse'
        if startIssue == endIssue
          dir = seriesDir
          action = 'comic'
        update.list.push {
          action: action
          dir: dir
          title: startDir
          start: startIssue
          end: endIssue
          cover: seriesCover
        }

  roundTimestamp: (ts) ->
    return Math.round(ts / BUCKET_WINDOW) * BUCKET_WINDOW

  getUpdates: ->
    return @updates

module.exports = UpdatesGenerator
