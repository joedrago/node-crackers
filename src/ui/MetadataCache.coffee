LRUCache = require './LRUCache'

class MetadataCache
  constructor: ->
    @cache = new LRUCache(100)

  load: (dir, cb) ->
    metadata = @cache.get(dir)
    if metadata
      # console.log "using cached metadata: #{dir}"
      setTimeout ->
        cb(metadata)
      , 0
    else
      metadataUrl = "#{dir}/meta.crackers"
      $.getJSON(metadataUrl)
      .success (metadata) =>
        # console.log "downloaded metadata: #{dir}"
        @cache.put dir, metadata
        cb(metadata)
      .error ->
        console.log "metadata download error"
        cb(null)

instance = null

load = (dir, cb) ->
  if not instance
    instance = new MetadataCache()
  return instance.load(dir, cb)

module.exports = load

'globals: instance MetadataCache'
