class Settings
  constructor: ->

  get: (key, defaultValue) ->
    value = window.localStorage.getItem(key)
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

  set: (key, value) ->
    # console.log "Settings.set(#{key}, '#{value}')"
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
  set: (key, value) ->
    ensureInstanceExists()
    return instance.set(key, value)
