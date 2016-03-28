# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
{Motion, spring} = require 'react-motion'
PubSub = require 'pubsub-js'

# Local requires
ImageCache = require './ImageCache'
TouchDiv = require './TouchDiv'
{div, el, img} = require './tags'

Auto =
  None: 0
  TopLeft: 1
  BottomRight: 2

Corner =
  TopLeft: 0
  TopRight: 1
  BottomRight: 2
  BottomLeft: 3

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
      index: 0
      loaded: false
      error: false
      touchCount: false
    @imageCache = new ImageCache()
    @preloadImageCount = 3
    @auto = Auto.None
    @autoScale = 1.5

    @setIndex(0, true)

  componentDidMount: ->
    console.log "ComicRenderer componentDidMount"
    @setState { touchCount: 0 }
    @keySubscription = PubSub.subscribe 'key', (msg, event) =>
      @onKeyPress(event)

  componentWillUnmount: ->
    console.log "ComicRenderer componentWillUnmount"
    PubSub.unsubscribe @keySubscription
    @setState { touchCount: 0 }
    @keySubscription = null
    @imageCache.flush()

  onKeyPress: (event) ->
    # console.log "onKeyPress #{event.keyCode}"
    switch event.keyCode
      when 49 # 1
        @setScale(1.5)
      when 50 # 2
        @setScale(2)
      when 51 # 3
        @setScale(3)
      when 52 # 4
        @setScale(4)

      when 81 # Q
        @zoomToCorner(Corner.TopLeft)
      when 87 # W
        @zoomToCorner(Corner.TopRight)
      when 65 # A
        @zoomToCorner(Corner.BottomLeft)
      when 83 # S
        @zoomToCorner(Corner.BottomRight)

      when 36 # Home
        @setIndex 0
      when 35 # End
        @setIndex 1000000

      when 37 # Left
        @setIndex @state.index-1
      when 39 # Right
        @setIndex @state.index+1

      when 68 # D
        @autoPrev()
      when 70 # F
        @autoNext()
    return

  setIndex: (index, initial) ->
    if index >= @props.metadata.pages
      index = @props.metadata.pages - 1
    if index < 0
      index = 0
    if not initial
      @setState {
        index: index
        loaded: false
        error: false
        imageSwipeX: 0
      }
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

  moveImage: (x, y, width, height, scale) ->
    centerPos = @calcImageCenterPos(width, height)

    if @state.touchCount == 0
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
        @setIndex @state.index-1
        # TODO: zoom to bottom right and set @auto to Auto.BottomRight after loading previous index
        # @zoomToCorner(Corner.BottomRight)
      when Auto.TopLeft
        @setScale(1, false)
        @auto = Auto.None
      when Auto.BottomRight
        @zoomToCorner(Corner.TopLeft)
    return

  autoNext: ->
    switch @auto
      when Auto.None
        @zoomToCorner(Corner.TopLeft)
      when Auto.TopLeft
        @zoomToCorner(Corner.BottomRight)
      when Auto.BottomRight
        @setIndex @state.index+1
    return

  zoomToCorner: (corner) ->
    imageScale = @state.imageScale
    if imageScale == 1
      imageScale = @autoScale
    imageSize = @calcImageSize(@state.originalImageWidth, @state.originalImageHeight, imageScale)
    x = 0
    y = 0
    switch corner
      when Corner.TopLeft
        x = 0
        y = 0
        @auto = Auto.TopLeft
      when Corner.TopRight
        x = -imageSize.width
        y = 0
      when Corner.BottomRight
        x = -imageSize.width
        y = -imageSize.height
        @auto = Auto.BottomRight
      when Corner.BottomLeft
        x = 0
        y = -imageSize.height
    @moveImage(x, y, imageSize.width, imageSize.height, imageScale)

  setScale: (scale, setAutoScale = true) ->
    imageSize = @calcImageSize(@state.originalImageWidth, @state.originalImageHeight, scale)
    @moveImage(@state.imageX, @state.imageY, imageSize.width, imageSize.height, scale)
    if setAutoScale
      @autoScale = scale
    return

  onClick: (x, y) ->
    # console.log "onClick #{x} #{y}"

  onNoTouches: ->
    if @state.imageSwipeX != 0
      newState = {
        imageSwipeX: 0
      }
      if @state.loaded
        if Math.abs(@state.imageSwipeX) > (@props.width / 8)
          direction = Math.sign(@state.imageSwipeX)
          @setIndex(@state.index - direction)
          return
      @setState { imageSwipeX: 0 }

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
      if dragOriginX > 50
        # Don't interfere with opening the left panel
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

  render: ->
    if @state.error
      return el Loader, {
        color: '#ff0000'
      }
    if not @state.loaded
      return el Loader, {
        color: '#222222'
      }

    return el Motion, {
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
            background: "url(\"#{@props.metadata.images[@state.index]}\")"
            backgroundRepeat: 'no-repeat'
            backgroundPosition: "#{values.imageX}px #{values.imageY}px"
            backgroundSize: "#{values.imageWidth}px #{values.imageHeight}px"
        }

module.exports = ComicRenderer
