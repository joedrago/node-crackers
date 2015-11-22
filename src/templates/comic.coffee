# ---------------------------------------------------------------------------------------
# Globals - eww!

touchTimestamp = null
zoomScales = [1.5, 2, 2.5, 3]
zoomScaleIndex = 0
zoomScale = zoomScales[zoomScaleIndex]
zoomX = 0
zoomY = 0
altZoom = getOptBool 'altzoom'
preloadImagesDefault = true
preloadImages = getOptBool('preload', preloadImagesDefault)
spaceHeld = false
spaceMovedZoom = false
helpShowing = false

prevUrl = "#inject{prev}"
nextUrl = "#inject{next}"

`
var comicImages = [
#inject{jslist}
null]
comicImages.pop()
`

# ---------------------------------------------------------------------------------------
# Auto state (A/D) for desktop nav

Auto =
  None: 0
  TopLeft: 1
  BottomRight: 2
autoState = Auto.None
autoStateOnShowEnd = Auto.None

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
    zX = Math.min(1, Math.floor(zoomX * 3) / 2)
    zY = Math.min(1, Math.floor(zoomY * 3) / 2)
    #zX = Math.round(zoomX * 2) / 2
    #zY = Math.round(zoomY * 2) / 2
    if (zX == 0.5) and (zY == 0.5)
      zoomX = Math.max(0, zoomX - (1/4)) * 2
      zoomY = Math.max(0, zoomY - (1/4)) * 2
    else
      zoomX = zX
      zoomY = zY

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
  autoState = Auto.None

fadeIn = ->
  if altZoom
    # console.log("fade in")
    $('#zoombox').finish().fadeTo(100, 0.5)

fadeOut = ->
  if altZoom
    # console.log("fade out")
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

zoomToCorner = (x, y) ->
  if (x == 0) and (x == 0)
    autoState = Auto.TopLeft
  else if (x == 1) and (y == 1)
    autoState = Auto.BottomRight
  else
    autoState = Auto.None

  zoomX = x
  zoomY = y
  updateZoom()

autoPrev = ->
  switch autoState
    when Auto.None
      autoStateOnShowEnd = Auto.BottomRight
      fotorama = $('.fotorama').data('fotorama')
      # fotorama.setOptions({ transition: 'crossfade' })
      fotorama.show('<')
    when Auto.TopLeft
      endZoom()
    when Auto.BottomRight
      zoomToCorner(0, 0)

autoNext = ->
  switch autoState
    when Auto.None
      zoomToCorner(0, 0)
    when Auto.TopLeft
      zoomToCorner(1, 1)
    when Auto.BottomRight
      fotorama = $('.fotorama').data('fotorama')
      # fotorama.setOptions({ transition: 'crossfade' })
      fotorama.show('>')

# ---------------------------------------------------------------------------------------
# Keyboard

$(document).keydown (event) ->
  console.log "keydown", event.keyCode
  if helpShowing
    helpShowing = false
    $('#help').fadeOut()

  switch event.keyCode
    # -----------------------------------------
    # Adjust scale

    # 1-4
    when 49, 50, 51, 52
      zoomScaleIndex = event.keyCode - 49
      zoomScale = zoomScales[zoomScaleIndex]
      updateZoom()

    # backtick
    when 192
      endZoom()

    # Space
    when 32
      spaceHeld = true
      autoState = Auto.None
      console.log "autoState: None (space)"

    # -----------------------------------------
    # Switch page

    # Z
    when 90
      autoState = Auto.None
      fotorama = $('.fotorama').data('fotorama')
      # fotorama.setOptions({ transition: 'crossfade' })
      fotorama.show('<')

    # X
    when 88
      autoState = Auto.None
      fotorama = $('.fotorama').data('fotorama')
      # fotorama.setOptions({ transition: 'crossfade' })
      fotorama.show('>')

    # -----------------------------------------
    # Zoom to corners

    # Q
    when 81
      zoomToCorner(0, 0)
    # W
    when 87
      zoomToCorner(1, 0)
    # A
    when 65
      zoomToCorner(0, 1)
    # S
    when 83
      zoomToCorner(1, 1)

    # -----------------------------------------
    # Auto mode

    # D
    when 68
      autoPrev()
    # F
    when 70
      autoNext()

    # -----------------------------------------
    # Switch issue / back to index

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

    # -----------------------------------------
    # Help

    # H, ?
    when 72, 191
      if not helpShowing
        helpShowing = true
        $('#help').fadeIn()

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
fotorama.on 'fotorama:showend', (e, fotorama, extra) ->
  if window.hasOwnProperty('onPage')
    window.onPage(fotorama.activeIndex+1)
  switch autoStateOnShowEnd
    when Auto.BottomRight
      zoomToCorner(1, 1)
  autoStateOnShowEnd = Auto.None
  # fotorama.setOptions({ transition: 'slide' })
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

  $("body").append "<a class=\"box indexbox\" href=\"../\"></a>"


# Image preloading code
console.log "preloading images: #{preloadImages}"
if preloadImages
  $("body").append "<div id=\"preloadbar\"><div id=\"preloadbarinner\"></div></div>"
  loadedImages = {}
  nextLoadIndex = 0
  loadNextImage = ->
    percentage = Math.floor(100 * (nextLoadIndex+1) / comicImages.length)
    $('#preloadbarinner').width("#{percentage}%")
    if nextLoadIndex < comicImages.length
      img = new Image()
      img.onload = ->
        loadNextImage()
      img.onerror = ->
        nextLoadIndex -= 1
        console.log "retrying #{comicImages[nextLoadIndex]}"
        loadNextImage()
      loadedImages[comicImages[nextLoadIndex]] = img
      console.log "Preloading #{comicImages[nextLoadIndex]}"
      img.src = comicImages[nextLoadIndex]
      nextLoadIndex += 1
    else
      console.log "Preloading complete."
      $('#preloadbar').fadeOut(2500)

  loadNextImage()

# ---------------------------------------------------------------------------------------
