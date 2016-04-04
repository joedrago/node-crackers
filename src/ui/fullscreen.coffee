fullscreenAvailable = ->
  available = false
  if document.documentElement.requestFullScreen
    return true
  if document.documentElement.mozRequestFullScreen
    return true
  if document.documentElement.webkitRequestFullScreen
    return true
  return false

fullscreenActive = ->
  active = document.fullscreenElement or document.webkitFullscreenElement or document.mozFullScreenElement or document.msFullscreenElement
  return (active != undefined)

fullscreenEnable = (enabled = true) ->
  return if not fullscreenAvailable()
  return if enabled == fullscreenActive()
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
fullscreenDisable = ->
  return fullscreenEnable(false)

# helper
fullscreenToggle = ->
  active = fullscreenActive()
  return fullscreenEnable(!active)

module.exports =
  available: fullscreenAvailable
  active: fullscreenActive
  enable: fullscreenEnable
  disable: fullscreenDisable
  toggle: fullscreenToggle
