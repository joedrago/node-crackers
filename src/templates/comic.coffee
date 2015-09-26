# ---------------------------------------------------------------------------------------
# Globals - eww!

touchTimestamp = null
zoomScales = [1.5, 2, 2.5, 3]
zoomScaleIndex = 0
zoomScale = zoomScales[zoomScaleIndex]
zoomX = 0
zoomY = 0
altZoom = getOptBool 'altzoom'
spaceHeld = false
spaceMovedZoom = false
helpShowing = false

prevUrl = "#inject{prev}"
nextUrl = "#inject{next}"

# ---------------------------------------------------------------------------------------
# Helpers

Number.prototype.clamp = (min, max) ->
  return Math.min(Math.max(this, min), max)

# ---------------------------------------------------------------------------------------
# Zoom

updateZoomPos = (t) ->
  zoomX = ((t.clientX - t.target.offsetLeft) / t.target.clientWidth).clamp(0, 1)
  zoomY = ((t.clientY - t.target.offsetTop) / t.target.clientHeight).clamp(0, 1)
  if altZoom
    zoomX = Math.round(zoomX)
    zoomY = Math.round(zoomY)

updateZoom = ->
  w = 0
  h = 0
  $(".fotorama__stage__frame.fotorama__active").each ->
    w = this.clientWidth
    h = this.clientHeight

  iw = 0
  ih = 0
  $(".fotorama__stage__frame.fotorama__active img").each ->
    iw = this.width
    ih = this.height

  transformOriginX = "0px"
  transformOriginY = "0px"

  if (w > 0) and (h > 0)
    offX = (zoomScale - 1) * -w * zoomX
    offY = (zoomScale - 1) * -h * zoomY

    # Attempt to clamp the scaled image offset so that it minimizes dead screen space
    if (iw > 0) and (ih > 0)
      diffw = w - iw
      diffh = h - ih
      offX += (zoomX - 0.5) * (diffw * zoomScale)
      offY += (zoomY - 0.5) * (diffh * zoomScale)

    # If the scaled image is smaller than an axis, attempt to center it post-scale
    scaledW = zoomScale * iw
    scaledH = zoomScale * ih
    if scaledW < w
      transformOriginX = "50%"
      offX = 0
    if scaledH < h
      transformOriginY = "50%"
      offY = 0

    tf = "translate("+offX+"px, "+offY+"px) scale("+zoomScale+")"
    $(".fotorama__stage__frame.fotorama__active").css {
      "transform-origin": "#{transformOriginX} #{transformOriginY}",
      "transform": tf,
    }

endZoom = ->
  $(".fotorama__stage__frame.fotorama__active").css {
    "transform-origin": "0px 0px",
    "transform": "translate(0px, 0px) scale(1)",
  }

fadeIn = ->
  if altZoom
    console.log("fade in")
    $('#zoombox').finish().fadeTo(100, 0.5)

fadeOut = ->
  if altZoom
    console.log("fade out")
    $('#zoombox').delay(250).fadeTo(250, 0)

# ---------------------------------------------------------------------------------------
# UI Handlers

window.touchMove = (event) ->
  event.preventDefault()
  updateZoomPos(event.changedTouches[0])
  updateZoom()

window.touchStart = (event) ->
  event.preventDefault()
  touchTimestamp = new Date().getTime()
  updateZoomPos(event.changedTouches[0])
  updateZoom()
  fadeIn()

window.touchEnd = (event) ->
  event.preventDefault()
  endTouchTimestamp = new Date().getTime()
  diff = endTouchTimestamp - touchTimestamp
  if diff < 100
    # Tap ends the zoom
    endZoom()
  fadeOut()

window.nextScale = (event) ->
  event.preventDefault()
  zoomScaleIndex = (zoomScaleIndex + 1) % zoomScales.length
  zoomScale = zoomScales[zoomScaleIndex]
  updateZoom()

# ---------------------------------------------------------------------------------------
# Keyboard

$(document).keydown (event) ->
  console.log "keydown", event.keyCode
  if helpShowing
    helpShowing = false
    $('#help').fadeOut()

  switch event.keyCode
    # 1-4
    when 49, 50, 51, 52
      zoomScaleIndex = event.keyCode - 49
      zoomScale = zoomScales[zoomScaleIndex]
      updateZoom()

    # backtick
    when 192
      endZoom()

    # Q
    when 81
      zoomX = 0
      zoomY = 0
      updateZoom()

    # W
    when 87
      zoomX = 1
      zoomY = 0
      updateZoom()

    # A
    when 65
      zoomX = 0
      zoomY = 1
      updateZoom()

    # S
    when 83
      zoomX = 1
      zoomY = 1
      updateZoom()

    # Z
    when 90
      fotorama = $('.fotorama').data('fotorama')
      fotorama.show('<')

    # X
    when 88
      fotorama = $('.fotorama').data('fotorama')
      fotorama.show('>')

    # N
    when 78
      if nextUrl
        window.location = nextUrl

    # P
    when 80
      if prevUrl
        window.location = prevUrl

    # B, I
    when 66, 73
      window.location = '../'

    # H, ?
    when 72, 191
      if not helpShowing
        helpShowing = true
        $('#help').fadeIn()

    # Space
    when 32
      spaceHeld = true

  return

$(document).keyup (event) ->
  switch event.keyCode
    # Space
    when 32
      spaceHeld = false
      if spaceMovedZoom
        spaceMovedZoom = false
      else
        endZoom()

  return

$(document).mousemove (event) ->
  if spaceHeld
    updateZoomPos(event)
    updateZoom()
    spaceMovedZoom = true

# ---------------------------------------------------------------------------------------
# Setup

fotorama = $('.fotorama')
fotorama.on 'fotorama:show fotorama:showend', (e, fotorama, extra) ->
  endZoom()
fotorama.fotorama()

if isMobile.any
  if altZoom
    $("body").append "<div id=\"zoombox\" class=\"altzoombox\" ontouchmove=\"touchMove(event)\" ontouchstart=\"touchStart(event)\" ontouchend=\"touchEnd(event)\"></div>"
    $("#zoombox").append "<div class=\"altzoomcross\"</div>"
  else
    $("body").append "<div id=\"zoombox\" class=\"box zoombox\" ontouchmove=\"touchMove(event)\" ontouchstart=\"touchStart(event)\" ontouchend=\"touchEnd(event)\"></div>"
    if isMobile.tablet
      # Calm down a little bit on the zoombox size/position.
      $('#zoombox').css "width",  "10vw"
      $('#zoombox').css "height", "10vh"
  fadeOut()

  $("body").append "<div class=\"box scalebox\" ontouchstart=\"nextScale(event)\"></div>"

  if prevUrl
    $("body").append "<a class=\"box prevbox\" href=\""+prevUrl+"\"></a>"
  if nextUrl
    $("body").append "<a class=\"box nextbox\" href=\""+nextUrl+"\"></a>"

# ---------------------------------------------------------------------------------------
