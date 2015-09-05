util = require 'util'

VERBOSE = false

internalLog = (type, args) ->
  if not VERBOSE and (type == 'verbose')
    return
  args.unshift("[#{type}]")
  util.log.apply(null, args)

module.exports = {}
for type in ['verbose', 'progress', 'warning', 'error', 'syntax']
  do (type) ->
    module.exports[type] = -> internalLog.call(null, type, Array.prototype.slice.call(arguments))

module.exports.setVerbose = (v) ->
  VERBOSE = v
  if v
    util.log "Verbose mode."
