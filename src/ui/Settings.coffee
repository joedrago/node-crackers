class Settings
  constructor: ->
    @cache = {}

  # The are purposefully string values, as localStorage only knows about strings.
  # Any settings not in this list should be considered an error.
  defaultValues:
    'comic.animation': 'true'
    'comic.autotouch': '0'
    'comic.autoZoomOut': 'false'
    'comic.confirmBinge': 'true'
    'comic.dblzoom1': '2'
    'comic.dblzoom2': '3'
    'comic.dblzoom3': '0'
    'comic.showPageNumber': 'true'
    'comic.spaceAutoRead': 'true'
    'comic.zoomgrid': 'false'
    'fakebackbutton.force': 'false'
    'fullscreen.overlay': 'false'
    'help.reminder': 'true'
    'show.reading': 'true'
    'show.unread': 'true'
    'show.completed': 'true'
    'show.ignored': 'false'
    'updates.detailed': 'false'

  defaultValue: (key) ->
    if @defaultValues.hasOwnProperty(key)
      return @defaultValues[key]
    console.error "Settings.defaultValue(): Unknown key #{key}"
    return null

  get: (key) ->
    if @cache.hasOwnProperty(key)
      value = @cache[key]
    else
      value = window.localStorage.getItem(key)
      if (value == null) or (value == undefined)
        value = @defaultValue(key)
      @cache[key] = value
    # console.log "Settings.get(#{key}): '#{value}'"
    return value

  getBool: (key) ->
    return (@get(key) == 'true')

  getFloat: (key) ->
    return parseFloat(@get(key))

  set: (key, value) ->
    # console.log "Settings.set(#{key}, '#{value}')"
    @cache[key] = String(value)
    window.localStorage.setItem(key, value)
    return

instance = null
ensureInstanceExists = ->
  if not instance
    instance = new Settings()
  return

settings =
  get: (key) ->
    ensureInstanceExists()
    return instance.get(key)
  getBool: (key) ->
    ensureInstanceExists()
    return instance.getBool(key)
  getFloat: (key) ->
    ensureInstanceExists()
    return instance.getFloat(key)
  set: (key, value) ->
    ensureInstanceExists()
    return instance.set(key, value)

module.exports = settings

'globals: instance ensureInstanceExists Settings'
