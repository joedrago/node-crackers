fullscreen =
  available: ->
    available = false
    if document.documentElement.requestFullScreen
      return true
    if document.documentElement.mozRequestFullScreen
      return true
    if document.documentElement.webkitRequestFullScreen
      return true
    return false

  active: ->
    active = document.fullscreenElement or document.webkitFullscreenElement or document.mozFullScreenElement or document.msFullscreenElement
    return (active != undefined)

  enable: (enabled = true) ->
    return if not fullscreen.available()
    return if enabled == fullscreen.active()
    if enabled
      if document.documentElement.requestFullScreen
        return document.documentElement.requestFullScreen()
      if document.documentElement.mozRequestFullScreen
        return document.documentElement.mozRequestFullScreen()
      if document.documentElement.webkitRequestFullScreen
        return document.documentElement.webkitRequestFullScreen(Element.ALLOW_KEYBOARD_INPUT)
    else
      if document.cancelFullScreen
        return document.cancelFullScreen()
      if document.mozCancelFullScreen
        return document.mozCancelFullScreen()
      if document.webkitCancelFullScreen
        return document.webkitCancelFullScreen()
    return

  # alias
  disable: ->
    return fullscreen.enable(false)

  # helper
  toggle: ->
    active = fullscreen.active()
    return fullscreen.enable(!active)

module.exports = fullscreen
