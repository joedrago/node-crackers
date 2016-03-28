LRUCache = require './LRUCache'

class MetadataCache
  constructor: ->
    @cache = new LRUCache(100)

module.exports = MetadataCache
