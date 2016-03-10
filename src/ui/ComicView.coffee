# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
PubSub = require 'pubsub-js'

# Local requires
ImageCache = require './ImageCache'
{div, el, img} = require './tags'

class ComicView extends React.Component
  @defaultProps:
    metadata: null

  constructor: (props) ->
    super props
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
          @setState {
            loaded: true
            imageWidth: info.width
            imageHeight: info.height
          }

  calcImageRect: ->
    viewAspectRatio = @props.width / @props.height
    imageAspectRatio = @state.imageWidth / @state.imageHeight
    if viewAspectRatio < imageAspectRatio
      aspectCorrectHeight = @props.width / imageAspectRatio
      rect = {
        x: 0
        y: (@props.height - aspectCorrectHeight) >> 1
        width: @props.width
        height: aspectCorrectHeight
      }
    else
      aspectCorrectWidth = @props.height * imageAspectRatio
      rect = {
        x: (@props.width - aspectCorrectWidth) >> 1
        y: 0
        width: aspectCorrectWidth
        height: @props.height
      }
    return rect

  render: ->
    if @state.error
      return el Loader, {
        color: '#ff0000'
      }
    if not @state.loaded
      return el Loader, {
        color: '#222222'
      }

    rect = @calcImageRect()
    return div {
        style:
          position: 'absolute'
          left: 0
          top: 0
          width: @props.width
          height: @props.height
          background: "url(\"#{@props.metadata.images[@state.index]}\")"
          backgroundRepeat: 'no-repeat'
          backgroundPosition: "#{rect.x}px #{rect.y}px"
          backgroundSize: "#{rect.width}px #{rect.height}px"
      }

module.exports = ComicView
