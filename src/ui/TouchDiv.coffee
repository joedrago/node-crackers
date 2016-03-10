# React
React = require 'react'
DOM = require 'react-dom'
{div, el, img} = require './tags'

# # how many pixels can you drag before it is actually considered a drag
ENGAGE_DRAG_DISTANCE = 30

class TouchDiv extends React.Component
  constructor: (props) ->
    super props
    @MOUSE_ID = 100
    @mouseDown = false
    @trackedTouches = []
    @dragX = 0
    @dragY = 0
    @dragging = false

  componentDidMount: ->
    # console.log "TouchDiv componentDidMount"
    node = DOM.findDOMNode(this)
    $(node).on 'mousedown', (event) =>
      event.preventDefault()
      @onTouchesBegan [{
        identifier: @MOUSE_ID
        clientX: event.clientX
        clientY: event.clientY
      }]
      @mouseDown = true
    $(node).on 'mouseup', (event) =>
      event.preventDefault()
      @onTouchesEnded [{
        identifier: @MOUSE_ID
        clientX: event.clientX
        clientY: event.clientY
      }]
      @mouseDown = false
    $(node).on 'mousemove', (event) =>
      event.preventDefault()
      if @mouseDown
        @onTouchesMoved [{
          identifier: @MOUSE_ID
          clientX: event.clientX
          clientY: event.clientY
        }]
    $(node).on 'touchstart', (event) =>
      event.preventDefault()
      @onTouchesBegan event.originalEvent.changedTouches
    $(node).on 'touchend', (event) =>
      event.preventDefault()
      @onTouchesEnded event.originalEvent.changedTouches
    $(node).on 'touchmove', (event) =>
      event.preventDefault()
      @onTouchesMoved event.originalEvent.changedTouches
    $(node).on 'mousewheel', (event) =>
      event.preventDefault()
      @props.listener.onZoom(event.clientX, event.clientY, event.deltaY)

  componentWillUnmount: ->
    # console.log "TouchDiv componentWillUnmount"
    node = DOM.findDOMNode(this)
    $(node).off 'mousedown'
    $(node).off 'mouseup'
    $(node).off 'mousemove'
    $(node).off 'touchstart'
    $(node).off 'touchend'
    $(node).off 'touchmove'
    $(node).off 'mousewheel'

  render: ->
    div {
      style: @props.style
    }

  calcDistance: (x1, y1, x2, y2) ->
    dx = x2 - x1
    dy = y2 - y1
    return Math.sqrt(dx*dx + dy*dy)

  setDragPoint: ->
    @dragX = @trackedTouches[0].x
    @dragY = @trackedTouches[0].y

  calcPinchAnchor: ->
    if @trackedTouches.length >= 2
      @pinchX = Math.floor((@trackedTouches[0].x + @trackedTouches[1].x) / 2)
      @pinchY = Math.floor((@trackedTouches[0].y + @trackedTouches[1].y) / 2)
      # console.log "pinch anchor set at #{@pinchX}, #{@pinchY}"

  addTouch: (id, x, y) ->
    for t in @trackedTouches
      if t.id == id
        return
    @trackedTouches.push {
      id: id
      x: x
      y: y
    }
    if @trackedTouches.length == 1
      @setDragPoint()
    if @trackedTouches.length == 2
      # We just added a second touch spot. Calculate the anchor for pinching now
      @calcPinchAnchor()
    # console.log "adding touch #{id}, tracking #{@trackedTouches.length} touches"

  removeTouch: (id, x, y) ->
    index = -1
    for i in [0...@trackedTouches.length]
      if @trackedTouches[i].id == id
        index = i
        break
    if index != -1
      @trackedTouches.splice(index, 1)
      if @trackedTouches.length == 1
        @setDragPoint()
      if index < 2
        # We just forgot one of our pinch touches. Pick a new anchor spot.
        @calcPinchAnchor()
      # console.log "forgetting id #{id}, tracking #{@trackedTouches.length} touches"

  updateTouch: (id, x, y) ->
    index = -1
    for i in [0...@trackedTouches.length]
      if @trackedTouches[i].id == id
        index = i
        break
    if index != -1
      # console.log "updating touch #{id}, tracking #{@trackedTouches.length} touches"
      @trackedTouches[index].x = x
      @trackedTouches[index].y = y

  onTouchesBegan: (touches) ->
    if @trackedTouches.length == 0
      @dragging = false
    for t in touches
      id = t.identifier
      x = t.clientX
      y = t.clientY
      @addTouch id, x, y
    if @trackedTouches.length > 1
      # They're pinching, don't even bother to emit a click
      @dragging = true

  onTouchesMoved: (touches) ->
    prevDistance = 0
    if @trackedTouches.length >= 2
      prevDistance = @calcDistance(@trackedTouches[0].x, @trackedTouches[0].y, @trackedTouches[1].x, @trackedTouches[1].y)
    if @trackedTouches.length == 1
      prevX = @trackedTouches[0].x
      prevY = @trackedTouches[0].y

    for t in touches
      @updateTouch(t.identifier, t.clientX, t.clientY)

    if @trackedTouches.length == 1
      # single touch, consider dragging
      dragDistance = @calcDistance @dragX, @dragY, @trackedTouches[0].x, @trackedTouches[0].y
      if @dragging or (dragDistance > ENGAGE_DRAG_DISTANCE)
        @dragging = true
        if dragDistance > 0.5
          dx = @trackedTouches[0].x - @dragX
          dy = @trackedTouches[0].y - @dragY
          #console.log "single drag: #{dx}, #{dy}"
          @props.listener.onDrag(dx, dy)
        @setDragPoint()

    else if @trackedTouches.length >= 2
      # at least two fingers present, check for pinch/zoom
      currDistance = @calcDistance(@trackedTouches[0].x, @trackedTouches[0].y, @trackedTouches[1].x, @trackedTouches[1].y)
      deltaDistance = currDistance - prevDistance
      if deltaDistance != 0
        #console.log "distance dragged apart: #{deltaDistance} [anchor: #{@pinchX}, #{@pinchY}]"
        @props.listener.onZoom(@pinchX, @pinchY, deltaDistance)

  onTouchesEnded: (touches) ->
    if @trackedTouches.length == 1 and not @dragging
      @props.listener.onClick(touches[0].clientX, touches[0].clientY)
    for t in touches
      @removeTouch t.identifier, t.clientX, t.clientY

module.exports = TouchDiv
