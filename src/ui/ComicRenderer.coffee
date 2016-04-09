# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
ReactCSSTransitionGroup = require 'react-addons-css-transition-group'
{Motion, spring} = require 'react-motion'
PubSub = require 'pubsub-js'

# Material UI components
IconButton = require 'material-ui/lib/icon-button'

# Local requires
ConfirmDialog = require './ConfirmDialog'
ImageCache = require './ImageCache'
TouchDiv = require './TouchDiv'
Settings = require './Settings'
{div, el, img, span} = require './tags'

Auto =
  None: 0
  TopLeft: 1
  BottomRight: 2

Number.prototype.clamp = (min, max) ->
  return Math.min(Math.max(this, min), max)

# How long to show the page number after a page change
PAGE_NUMBER_DISPLAY_MS = 700

class ComicRenderer extends React.Component
  @defaultProps:
    metadata: null

  constructor: (props) ->
    super props
    @springConfig =
      stiffness: 500
      damping: 40
      precision: 1
    @MAX_SCALE = 3
    @state =
      index: -1
      loaded: false
      error: false
      touchCount: false
      confirmCB: null
    @imageCache = new ImageCache()
    @preloadImageCount = 3
    @auto = Auto.None
    @autoScale = 1.5
    @pageNumberTimer = null

    # console.log "ComicRenderer", @props
    index = 0
    if @props.page != null
      index = @props.page - 1
    @setIndex(index, { initial: true })

  componentDidMount: ->
    # console.log "ComicRenderer componentDidMount"
    @setState { touchCount: 0 }
    @keySubscription = PubSub.subscribe 'key', (msg, event) =>
      @onKeyPress(event)

  componentWillUnmount: ->
    # console.log "ComicRenderer componentWillUnmount"
    PubSub.unsubscribe @keySubscription
    @setState { touchCount: 0 }
    @keySubscription = null
    @imageCache.flush()
    if @pageNumberTimer != null
      clearTimeout(@pageNumberTimer)
      @pageNumberTimer = null

  componentWillReceiveProps: (nextProps) ->
    if (@props.width != nextProps.width) or (@props.height != nextProps.height)
      # Size of screen changed. Unzoom and recenter.
      @setScale(1, false)

  onKeyPress: (event) ->
    # console.log "onKeyPress #{event.keyCode}"
    switch event.keyCode
      when 48 # 0
        @setScale(1, false)
      when 49 # 1
        @setScale(1.5)
      when 50 # 2
        @setScale(2)
      when 51 # 3
        @setScale(3)
      when 52 # 4
        @setScale(4)

      when 81 # Q
        @zoomToCorner(0, 0)
      when 87 # W
        @zoomToCorner(1, 0)
      when 65 # A
        @zoomToCorner(0, 1)
      when 83 # S
        @zoomToCorner(1, 1)

      when 36 # Home
        @setIndex 0
      when 35 # End
        @setIndex 1000000

      when 37, 90  # Left, Z
        @setIndex @state.index-1, { offer: true }
      when 39, 88  # Right, X
        @setIndex @state.index+1, { offer: true }

      when 68 # D
        @autoPrev()
      when 70 # F
        @autoNext()

      when 78 # N
        if @props.metadata.next
          hash = "#comic/"+encodeURIComponent("#{@props.metadata.next}").replace("%2F", "/")
          @props.redirect hash
      when 80 # P
        if @props.metadata.prev
          hash = "#comic/"+encodeURIComponent("#{@props.metadata.prev}").replace("%2F", "/")
          @props.redirect hash
    return

  setIndex: (index, opts={}) ->
    # console.log "setIndex(#{index}, #{opts.initial})"
    # whether or not we're attempting to step 'out of bounds' (swipe before first page or after last page)
    outOfBounds = false
    if index >= @props.metadata.pages
      index = @props.metadata.pages - 1
      outOfBounds = 'next'
    if index < 0
      index = 0
      outOfBounds = 'prev'
    if index == @state.index
      if opts.initial
        @state.showPageNumber = true
      else
        @setState {
          showPageNumber: true
        }
    else
      if opts.initial
        @state.index = index
        @state.showPageNumber = true
      else
        @setState {
          index: index
          loaded: false
          error: false
          showPageNumber: true
          imageSwipeX: 0
        }
        @props.onViewPage(@props.dir, index + 1)
      @auto = Auto.None

      imagesToPreload = @props.metadata.images.slice(@state.index+1, @state.index+1 + @preloadImageCount)
      for image in imagesToPreload
        @imageCache.load image

      @imageCache.load @props.metadata.images[@state.index], (info) =>
        # is this a notification about the image we're currently trying to display?
        if info.url == @props.metadata.images[@state.index]
          if info.error
            @setState { error: true }
          else
            imageSize = @calcImageSize(info.width, info.height, 1)
            imagePos = @calcImageCenterPos(imageSize.width, imageSize.height)
            @setState {
              loaded: true
              originalImageWidth: info.width
              originalImageHeight: info.height
              imageX: imagePos.x
              imageY: imagePos.y
              imageWidth: imageSize.width
              imageHeight: imageSize.height
              imageScale: 1
              imageSwipeX: 0
            }

    if @pageNumberTimer != null
      clearTimeout(@pageNumberTimer)
    @pageNumberTimer = setTimeout =>
      @setState { showPageNumber: false}
      @pageNumberTimer = null
    , PAGE_NUMBER_DISPLAY_MS

    if outOfBounds and opts.offer
      # We're attempting to scroll outside of the comic via direct user action
      offerIssue = null
      switch outOfBounds
        when 'next'
          if @props.metadata.next
            offerIssue = @props.metadata.next
            offerTitle = 'Binge detected! Keep going?'
            offerAdjective = 'next'
        when 'prev'
          if @props.metadata.prev
            offerIssue = @props.metadata.prev
            offerTitle = 'Leave this issue?'
            offerAdjective = 'previous'

      if offerIssue and (offerIssue.length > 0)
        offerHash = "#comic/"+encodeURIComponent("#{offerIssue}").replace("%2F", "/")
        if Settings.getBool("comic.confirmBinge")
          @setState {
            confirmTitle: offerTitle
            confirmText: "Would you like to go to the #{offerAdjective} issue? (#{offerIssue})"
            confirmCB: (confirmed) =>
              if not confirmed
                return
              @props.redirect(offerHash)
          }
        else
          @props.redirect(offerHash)

  moveImage: (x, y, width, height, scale) ->
    # console.log("moveImage(#{x}, #{y}, #{width}, #{height}, #{scale})")
    centerPos = @calcImageCenterPos(width, height)

    if width < @props.width
      # width fits completely, just center it
      x = centerPos.x
    else
      # clamp to fit in the screen bounds
      if x > 0
        x = 0
      if (x + width) < @props.width
        x = @props.width - width

    if height < @props.height
      # height fits completely, just center it
      y = centerPos.y
    else
      # clamp to fit in the screen bounds
      if y > 0
        y = 0
      if (y + height) < @props.height
        y = @props.height - height

    @setState {
      imageX: x
      imageY: y
      imageWidth: width
      imageHeight: height
      imageScale: scale
      imageSwipeX: 0
    }

  autoPrev: ->
    switch @auto
      when Auto.None
        @setIndex @state.index-1, { offer: true }
        # TODO: zoom to bottom right and set @auto to Auto.BottomRight after loading previous index
        # @zoomToCorner(1, 1)
      when Auto.TopLeft
        @setScale(1, false)
        @auto = Auto.None
      when Auto.BottomRight
        @zoomToCorner(0, 0)
    return

  autoNext: ->
    switch @auto
      when Auto.None
        @zoomToCorner(0, 0)
      when Auto.TopLeft
        @zoomToCorner(1, 1)
      when Auto.BottomRight
        @setIndex @state.index+1, { offer: true }
    return

  zoomToCorner: (zoomX, zoomY, useFirstZoomLevel=false) ->
    imageScale = @state.imageScale
    if imageScale == 1
      if useFirstZoomLevel
        imageScale = Settings.getFloat("comic.dblzoom1")
      else
        imageScale = @autoScale
    # console.log("zoomToCorner(#{zoomX}, #{zoomY}, #{useFirstZoomLevel}) scale: #{imageScale}")
    imageSize = @calcImageSize(@state.originalImageWidth, @state.originalImageHeight, imageScale)
    if (zoomX == 0) and (zoomY == 0)
      @auto = Auto.TopLeft
    if (zoomX == 1) and (zoomY == 1)
      @auto = Auto.BottomRight
    maxScrollX = @props.width - imageSize.width
    maxScrollY = @props.height - imageSize.height
    x = zoomX * maxScrollX
    y = zoomY * maxScrollY
    @moveImage(x, y, imageSize.width, imageSize.height, imageScale)

  setScale: (scale, setAutoScale = true) ->
    imageSize = @calcImageSize(@state.originalImageWidth, @state.originalImageHeight, scale)
    @moveImage(@state.imageX, @state.imageY, imageSize.width, imageSize.height, scale)
    if setAutoScale
      @autoScale = scale
    return

  onClick: (x, y) ->
    # console.log "onClick #{x} #{y}"

  onDoubleTap: (x, y) ->
    scaleTiers = [1]
    if (zoom1 = Settings.getFloat("comic.dblzoom1")) > 1
      scaleTiers.push zoom1
      if (zoom2 = Settings.getFloat("comic.dblzoom2")) > 1
        scaleTiers.push zoom2
        if (zoom3 = Settings.getFloat("comic.dblzoom3")) > 1
          scaleTiers.push zoom3
    # console.log "scaleTiers", scaleTiers

    scaleIndex = 0
    for s, index in scaleTiers
      if @state.imageScale < s
        break
      scaleIndex = index
    # scaleIndex is now the closest scale to something in scaleTiers
    # Now advance to the 'next' tier
    scaleIndex = (scaleIndex + 1) % scaleTiers.length
    # console.log "onDoubleTap(#{x}, #{y}), scaling to index #{scaleIndex} (#{scaleTiers[scaleIndex]})"
    @zoomTo(x, y, scaleTiers[scaleIndex])

  onNoTouches: ->
    if @state.imageSwipeX != 0
      newState = {
        imageSwipeX: 0
      }
      if @state.loaded
        if Math.abs(@state.imageSwipeX) > (@props.width / 10)
          direction = Math.sign(@state.imageSwipeX)
          @setIndex(@state.index - direction, { offer: true })
          return
      @setState { imageSwipeX: 0 }

    autoZoomOutThreshold = 1.1
    if Settings.getBool("comic.autoZoomOut")
      # console.log "comic.autoZoomOut is true"
      autoZoomOutThreshold = 10 # zoom out when the person lets go, no matter what
    if (@state.imageScale > 1) and (@state.imageScale < autoZoomOutThreshold)
      # Too close to unzoomed, just force it
      @setScale(1, false)

  onTouchCount: (touchCount) ->
    # console.log "onTouchCount(#{touchCount})"
    @setState { touchCount: touchCount }
    if touchCount == 0
      @moveImage(@state.imageX, @state.imageY, @state.imageWidth, @state.imageHeight, @state.imageScale)

  onDrag: (dx, dy, dragOriginX, dragOriginY) ->
    # console.log "onDrag #{dx} #{dy}"
    if not @state.loaded
      return
    if @state.imageScale == 1
      @setState { imageSwipeX: @state.imageSwipeX + dx }
      return
    newX = @state.imageX + dx
    newY = @state.imageY + dy
    @moveImage(newX, newY, @state.imageWidth, @state.imageHeight, @state.imageScale)

  onZoom: (x, y, dist) ->
    # console.log "onZoom #{x} #{y} #{dist}"
    if not @state.loaded
      return
    imageScale = @state.imageScale + (dist / 100)
    if imageScale < 1
      imageScale = 1
      @auto = Auto.None
    if imageScale > @MAX_SCALE
      imageScale = @MAX_SCALE

    @zoomTo(x, y, imageScale)

  zoomTo: (x, y, imageScale) ->
    # calculate the cursor position in normalized image coords
    normalizedImagePosX = (x - @state.imageX) / @state.imageWidth
    normalizedImagePosY = (y - @state.imageY) / @state.imageHeight

    imageSize = @calcImageSize(@state.originalImageWidth, @state.originalImageHeight, imageScale)
    imagePos = {
      x: x - (normalizedImagePosX * imageSize.width)
      y: y - (normalizedImagePosY * imageSize.height)
    }
    @moveImage(imagePos.x, imagePos.y, imageSize.width, imageSize.height, imageScale)

  calcImageSize: (imageWidth, imageHeight, imageScale) ->
    viewAspectRatio = @props.width / @props.height
    imageAspectRatio = imageWidth / imageHeight
    if viewAspectRatio < imageAspectRatio
      size = {
        width: @props.width
        height: @props.width / imageAspectRatio
      }
    else
      size = {
        width: @props.height * imageAspectRatio
        height: @props.height
      }
    size.width *= imageScale
    size.height *= imageScale
    return size

  calcImageCenterPos: (imageWidth, imageHeight) ->
    return {
      x: (@props.width  - imageWidth ) >> 1
      y: (@props.height - imageHeight) >> 1
    }

  inLandscape: ->
    return (@props.width > @props.height)

  updateZoomGrid: (t) ->
    zoomX = ((t.clientX - t.target.offsetLeft) / t.target.clientWidth).clamp(0, 1)
    zoomY = ((t.clientY - t.target.offsetTop) / t.target.clientHeight).clamp(0, 1)
    zX = Math.min(1, Math.floor(zoomX * 3) / 2)
    zY = Math.min(1, Math.floor(zoomY * 3) / 2)
    if (zX == 0.5) and (zY == 0.5)
      zoomX = Math.max(0, zoomX - (1/4)) * 2
      zoomY = Math.max(0, zoomY - (1/4)) * 2
    else
      zoomX = zX
      zoomY = zY
    @zoomToCorner(zoomX, zoomY, true)

  onZoomGridStart: (t) ->
    $('#zoomgrid').finish().fadeTo(100, 0.5)
    @zoomgridStartTime = new Date().getTime()
    @updateZoomGrid(t)
  onZoomGridMove: (t) ->
    @updateZoomGrid(t)
  onZoomGridEnd: (t) ->
    $('#zoomgrid').delay(250).fadeTo(250, 0)
    endTouchTimestamp = new Date().getTime()
    diff = endTouchTimestamp - @zoomgridStartTime
    if diff < 100
      # Tap ends the zoom
      @setScale(1, false)

  render: ->
    if @state.error
      return el Loader, {
        color: '#ff0000'
      }

    elements = []

    elements.push el ConfirmDialog, {
        key: "confirmdialog"
        open: (@state.confirmCB != null)
        yes: 'Yes'
        no: 'No'
        title: @state.confirmTitle
        text: @state.confirmText
        cb: (confirmed) =>
          if @state.confirmCB
            @state.confirmCB(confirmed)
            @setState { confirmCB: null }
      }

    pageNumber = []
    if Settings.getBool("comic.showPageNumber") and @state.showPageNumber
      pageNumber.push div {
        key: 'pagenumber'
        style:
          position: 'absolute'
          width: '100%'
          bottom: '5%'
          textAlign: 'center'
          fontSize: '1.4em'
          zIndex: 3
          pointerEvents: 'none'
          fontFamily: 'monospace'
          color: '#ffffff'
          textShadow: '3px 3px #000000'
      }, span {
        key: 'pagedisplayinner'
        style:
          backgroundColor: 'rgba(0, 0, 0, 0.5)'
          marginLeft: 'auto'
          marginRight: 'auto'
          padding: '6px 9px 6px 9px'
          borderRadius: '3px'
      }, "Page #{@state.index+1} / #{@props.metadata.pages}"
    elements.push el ReactCSSTransitionGroup, {
      key: 'pagenumbertransition'
      transitionName: 'fademe'
      transitionEnterTimeout: 100
      transitionLeaveTimeout: 300
    }, pageNumber

    # ZoomGrid
    if Settings.getBool("comic.zoomgrid")
      elements.push div {
        id: 'zoomgrid'
        className: 'zoomgrid'
        onTouchStart: (e) =>
          e.preventDefault()
          @onZoomGridStart(e.changedTouches[0])
        onTouchMove: (e) =>
          e.preventDefault()
          @onZoomGridMove(e.changedTouches[0])
        onTouchEnd: (e) =>
          e.preventDefault()
          @onZoomGridEnd(e.changedTouches[0])
      }, [
        div {
          className: 'zoomgridinner'
        }
      ]

    autotouch = Settings.getFloat('comic.autotouch')
    if @inLandscape() and (autotouch > 0)
      # Autoread!
      elements.push el IconButton, {
          key: "autoread_back"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 0
            top: 40
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @autoScale = autotouch
              @autoPrev()
            , 0
        }, 'call_missed'

      elements.push el IconButton, {
          key: "autoread_forward"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 0
            top: 80
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @autoScale = autotouch
              @autoNext()
            , 0
        }, 'call_missed_outgoing'

      elements.push el IconButton, {
          key: "zoomtocorner_q"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 0
            bottom: 30
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @autoScale = autotouch
              @zoomToCorner(0, 0)
            , 0
        }, 'check_box_outline_blank'

      elements.push el IconButton, {
          key: "zoomtocorner_w"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 30
            bottom: 30
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @autoScale = autotouch
              @zoomToCorner(1, 0)
            , 0
        }, 'check_box_outline_blank'

      elements.push el IconButton, {
          key: "zoomtocorner_a"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 0
            bottom: 0
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @autoScale = autotouch
              @zoomToCorner(0, 1)
            , 0
        }, 'check_box_outline_blank'

      elements.push el IconButton, {
          key: "zoomtocorner_s"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 30
            bottom: 0
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @autoScale = autotouch
              @zoomToCorner(1, 1)
            , 0
        }, 'check_box_outline_blank'

    if @state.loaded
      # TODO: Reduce copypasta here
      if Settings.getBool("comic.animation")
        elements.push el Motion, {
            key: 'animimage'
            style:
              imageX: spring(@state.imageX, @springConfig)
              imageY: spring(@state.imageY, @springConfig)
              imageWidth: spring(@state.imageWidth, @springConfig)
              imageHeight: spring(@state.imageHeight, @springConfig)
          }, (values) =>
            el TouchDiv, {
              listener: this
              width: @props.width
              height: @props.height
              style:
                id: 'page'
                position: 'absolute'
                left: 0
                top: 0
                width: @props.width
                height: @props.height
                backgroundColor: '#111111'
                backgroundImage: "url(\"#{@props.metadata.images[@state.index]}\")"
                backgroundRepeat: 'no-repeat'
                backgroundPosition: "#{values.imageX}px #{values.imageY}px"
                backgroundSize: "#{values.imageWidth}px #{values.imageHeight}px"
            }
      else
        elements.push el TouchDiv, {
          key: 'animimage'
          listener: this
          width: @props.width
          height: @props.height
          style:
            id: 'page'
            position: 'absolute'
            left: 0
            top: 0
            width: @props.width
            height: @props.height
            backgroundColor: '#111111'
            backgroundImage: "url(\"#{@props.metadata.images[@state.index]}\")"
            backgroundRepeat: 'no-repeat'
            backgroundPosition: "#{@state.imageX}px #{@state.imageY}px"
            backgroundSize: "#{@state.imageWidth}px #{@state.imageHeight}px"
        }
    else
      elements.push el Loader, {
        key: 'loader'
        color: '#222222'
      }
    return div {}, elements

module.exports = ComicRenderer
