# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
PubSub = require 'pubsub-js'

# Local requires
ImageCache = require './ImageCache'
TouchDiv = require './TouchDiv'
{div, el, img} = require './tags'

class ComicView extends React.Component
  @defaultProps:
    metadata: null

  constructor: (props) ->
    super props
    @MAX_SCALE = 3
    @state =
      index: 0
      loaded: false
      error: false
    @imageCache = new ImageCache()
    @preloadImageCount = 3

    @setIndex(0, true)

  componentDidMount: ->
    console.log "ComicView componentDidMount"
    @keySubscription = PubSub.subscribe 'key', (msg, event) =>
      @onKeyPress(event)

  componentWillUnmount: ->
    console.log "ComicView componentWillUnmount"
    PubSub.unsubscribe @keySubscription
    @keySubscription = null
    @imageCache.flush()

  onKeyPress: (event) ->
    if event.keyCode == 37 # left
      @setIndex @state.index-1
    else if event.keyCode == 39 # right
      @setIndex @state.index+1

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
      }

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
          }

  moveImage: (x, y, width, height, scale) ->
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
    }

  onClick: (x, y) ->
    # console.log "onClick #{x} #{y}"

  onDrag: (dx, dy) ->
    # console.log "onDrag #{dx} #{dy}"
    if not @state.loaded
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

    return el TouchDiv, {
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
          backgroundPosition: "#{@state.imageX}px #{@state.imageY}px"
          backgroundSize: "#{@state.imageWidth}px #{@state.imageHeight}px"
      }

module.exports = ComicView
