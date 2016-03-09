LRUCache = require './LRUCache'

class ImageCache
  constructor: (@size = 10) ->
    @cache = new LRUCache(@size)
    @MAX_RETRIES = 3

  notify: (entry) ->
    info =
      url: entry.url
      loaded: entry.loaded
      error: entry.error
      width: entry.width
      height: entry.height
    for cb in entry.callbacks
      if cb
        setTimeout ->
          # console.log "ImageCache.notify", info
          cb(info)
        , 0
    entry.callbacks = []
    return

  flush: ->
    # console.log "ImageCache.flush()"
    @cache.removeAll()

  load: (url, cb) ->
    # console.log "ImageCache.load(#{url})"
    entry = @cache.get(url)
    if entry and (entry.loaded or entry.error)
      # console.log "ImageCache.load(#{url}) existing entry", @cache.toArray()
      entry.callbacks.push cb
      @notify(entry)
      return

    image = new Image()
    entry =
      url: url
      image: image
      callbacks: [cb]
      loaded: false
      error: false
      errorCount: 0
      width: 0
      height: 0
    @cache.put(url, entry)
    # console.log "ImageCache.load(#{url}) new entry", @cache.toArray()

    image.onload = =>
      # console.log "ImageCache image.onload(#{entry.url})"
      entry.loaded = true
      entry.error = false
      entry.width = entry.image.width
      entry.height = entry.image.height
      @notify(entry)
    image.onerror = =>
      # console.log "ImageCache image.onerror(#{entry.url})"
      entry.loaded = false
      entry.errorCount += 1
      if entry.errorCount < @MAX_RETRIES
        cacheBreakerUrl = entry.url + '?' + +new Date
        entry.image.src = cacheBreakerUrl
        # console.log "ImageCache retrying (retry ##{entry.errorCount}) #{cacheBreakerUrl}"
      else
        entry.error = true
        @notify(entry)
    image.src = url

module.exports = ImageCache
