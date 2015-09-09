# ---------------------------------------------------------------------------------------
# Globals - eww!

touchTimestamp = null
zoomScales = [1.5, 2, 2.5, 3]
zoomScaleIndex = 0
zoomScale = zoomScales[zoomScaleIndex]
zoomX = 0
zoomY = 0
altZoom = getOptBool 'altzoom'

# ---------------------------------------------------------------------------------------
# Helpers

Number.prototype.clamp = (min, max) ->
  return Math.min(Math.max(this, min), max)

# ---------------------------------------------------------------------------------------
# Zoom

updateZoomPos = (event) ->
  t = event.changedTouches[0]
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

  if (w > 0) and (h > 0)
    offX = (zoomScale - 1) * -w * zoomX
    offY = (zoomScale - 1) * -h * zoomY

    # Attempt to clamp the scaled image offset so that it minimizes dead screen space
    if (iw > 0) and (ih > 0)
      diffw = w - iw
      diffh = h - ih
      offX += (zoomX - 0.5) * (diffw * zoomScale)
      offY += (zoomY - 0.5) * (diffh * zoomScale)

    tf = "translate("+offX+"px, "+offY+"px) scale("+zoomScale+")"
    $(".fotorama__stage__frame.fotorama__active").css {
      "transform-origin": "0px 0px",
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
  updateZoomPos(event)
  updateZoom()

window.touchStart = (event) ->
  event.preventDefault()
  touchTimestamp = new Date().getTime()
  updateZoomPos(event)
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

  prevUrl = "#inject{prev}"
  nextUrl = "#inject{next}"
  if prevUrl
    $("body").append "<a class=\"box prevbox\" href=\""+prevUrl+"\"></a>"
  if nextUrl
    $("body").append "<a class=\"box nextbox\" href=\""+nextUrl+"\"></a>"

# ---------------------------------------------------------------------------------------
