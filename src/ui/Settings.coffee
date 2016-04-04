class Settings
  constructor: ->
    @cache = {}

  get: (key, defaultValue) ->
    if @cache.hasOwnProperty(key)
      value = @cache[key]
    else
      value = window.localStorage.getItem(key)
      @cache[key] = value
      if (value == null) or (value == undefined)
        value = defaultValue
    # console.log "Settings.get(#{key}): '#{value}'"
    return value

  getBool: (key, defaultValue) ->
    value = @get(key, null)
    if value == null
      value = defaultValue
    else
      value = (value == 'true')
    # console.log "Settings.getBool(#{key}): '#{value}'"
    return value

  getFloat: (key, defaultValue) ->
    value = @get(key, null)
    if value == null
      value = defaultValue
    else
      value = parseFloat(value)
    # console.log "Settings.getFloat(#{key}): '#{value}'"
    return value

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

module.exports =
  get: (key, defaultValue) ->
    ensureInstanceExists()
    return instance.get(key, defaultValue)
  getBool: (key, defaultValue) ->
    ensureInstanceExists()
    return instance.getBool(key, defaultValue)
  getFloat: (key, defaultValue) ->
    ensureInstanceExists()
    return instance.getFloat(key, defaultValue)
  set: (key, value) ->
    ensureInstanceExists()
    return instance.set(key, value)
