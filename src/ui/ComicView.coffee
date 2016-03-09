# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
PubSub = require 'pubsub-js'

# Local requires
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
    @image = null

    @setIndex(0, true)

  componentDidMount: ->
    console.log "ComicView componentDidMount"
    @keySubscription = PubSub.subscribe 'key', (msg, event) =>
      @onKeyPress(event)

  componentWillUnmount: ->
    console.log "ComicView componentWillUnmount"
    PubSub.unsubscribe @keySubscription
    @keySubscription = null

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
    @image = new Image()
    @image.onload = =>
      @setState {
        loaded: true
        imageWidth: @image.width
        imageHeight: @image.height
      }
    @image.onerror = =>
      @setState { error: true }
    @image.src = @props.metadata.images[@state.index]

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
        color: '#aaffaa'
      }

    # return div {
    #   style:
    #     color: '#ffffff'
    # }, "index[#{@state.index} / #{@props.metadata.pages}] #{@props.width}x#{@props.height} #{@state.imageWidth}x#{@state.imageHeight}"

    rect = @calcImageRect()
    return img {
      style:
        position: 'absolute'
        left: rect.x
        top: rect.y
        width: rect.width
        height: rect.height
      src: @props.metadata.images[@state.index]
    }

module.exports = ComicView
