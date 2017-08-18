cfs = require './cfs'
constants = require './constants'
moment = require 'moment'
path = require 'path'
BucketsGenerator = require './BucketsGenerator'

class UpdatesGenerator
  constructor: (@rootDir) ->
    @updates = new BucketsGenerator(@rootDir, @roundTimestamp).getBuckets()

  roundTimestamp: (ts) ->
    BUCKET_WINDOW = 24 * 60 * 60
    return Math.round(ts / BUCKET_WINDOW) * BUCKET_WINDOW

  getUpdates: ->
    return @updates

module.exports = UpdatesGenerator
