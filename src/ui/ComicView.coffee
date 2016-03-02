React = require 'react'
DOM = require 'react-dom'
{div, img} = require './tags'

class ComicView extends React.Component
  @defaultProps:
    src: null

  constructor: (props) ->
    super props
    @state =
      src: props.src

  render: ->
    if @state.src
      img {
        src: @state.src
      }
    else
      div(null, "Loading...")

module.exports = ComicView
