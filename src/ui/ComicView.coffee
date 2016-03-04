React = require 'react'
DOM = require 'react-dom'
{div, img} = require './tags'

class ComicView extends React.Component
  @defaultProps:
    dir: '.'

  constructor: (props) ->
    super props
    @state =
      dir: props.dir

  render: ->
    if @state.src
      img {
        src: @state.src
      }
    else
      div(null, "Loading...")

module.exports = ComicView
