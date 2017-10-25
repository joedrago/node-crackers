cfs = require './cfs'
constants = require './constants'
moment = require 'moment'
path = require 'path'
BucketsGenerator = require './BucketsGenerator'

class StockGenerator
  constructor: (@rootDir) ->
    buckets = new BucketsGenerator(@rootDir, @roundTimestamp).getBuckets()
    @stock = ""
    if buckets.length == 1
      for comic in buckets[0].list
        if comic.start? and comic.end?
          if comic.start == comic.end
            @stock += "#{comic.title} ##{comic.start}\n"
          else
            @stock += "#{comic.title} ##{comic.start}-#{comic.end}\n"
        else
          @stock += "#{comic.title}\n"
    return

  roundTimestamp: (ts) ->
    return 0

  getStock: ->
    return @stock

module.exports = StockGenerator
