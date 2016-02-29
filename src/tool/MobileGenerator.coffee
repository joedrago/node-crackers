cfs = require './cfs'
constants = require './constants'
fs = require 'fs'
log = require './log'
template = require './template'

class MobileGenerator
  constructor: (@rootDir) ->
    @mobileFilename = cfs.join(@rootDir, constants.MOBILE_FILENAME)

  generate: ->
    outputText = template('mobile_html', { title: cfs.getRootTitle(@rootDir) })
    fs.writeFileSync @mobileFilename, outputText
    log.progress "Generated mobile page (#{constants.MOBILE_FILENAME})"

module.exports = MobileGenerator
