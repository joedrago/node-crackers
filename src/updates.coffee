cfs = require './cfs'
fs = require 'fs'
moment = require 'moment'
path = require 'path'

BUCKET_WINDOW = 24 * 60 * 60

formatTimestamp = (ts) ->
  return moment(ts * 1000).format('MMMM Do, YYYY')

sortByRelativeDir = (a, b) ->
  return -1 if a.relativeDir < b.relativeDir
  return  1 if a.relativeDir > b.relativeDir
  return  0

sortByTimestampDescending = (a, b) ->
  return  1 if a.timestamp < b.timestamp
  return -1 if a.timestamp > b.timestamp
  return  0

class Updates
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
        date: formatTimestamp(bucket.start)
      @updates.push update

      bucket.list.sort(sortByRelativeDir)
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
            update.list.push {
              dir: startDir
              start: startIssue
              end: endIssue
            }
            startDir = null
          if issue > 0
            startDir = parsed.dir
            startIssue = endIssue = issue
          else
            update.list.push {
              dir: comic.relativeDir
            }
        else
          endIssue = issue

      if startDir and (startIssue > 0) and (endIssue > 0)
        update.list.push {
          dir: startDir
          start: startIssue
          end: endIssue
        }

  roundTimestamp: (ts) ->
    return Math.round(ts / BUCKET_WINDOW) * BUCKET_WINDOW

  getUpdates: ->
    return @updates

module.exports = Updates
