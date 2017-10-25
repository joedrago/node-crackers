cfs = require './cfs'
constants = require './constants'
moment = require 'moment'
path = require 'path'

class BucketsGenerator
  constructor: (@rootDir, roundTimestamp) ->
    @comics = cfs.gatherComics(@rootDir)
    @comics.sort (a, b) ->
      return  1 if a.timestamp < b.timestamp
      return -1 if a.timestamp > b.timestamp
      return  0

    timeBuckets = []
    bucket = null
    for comic in @comics
      ts = roundTimestamp(comic.timestamp)
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

    @buckets = []
    for bucket in timeBuckets
      update =
        list: []
        pdate: moment(bucket.start * 1000).format('MMMM Do, YYYY')
        date:  moment(bucket.start * 1000).format('YYYYMMDD')
      @buckets.push update

      bucket.list.sort (a, b) ->
        return -1 if a.relativeDir < b.relativeDir
        return  1 if a.relativeDir > b.relativeDir
        return  0

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

  getBuckets: ->
    return @buckets

module.exports = BucketsGenerator
