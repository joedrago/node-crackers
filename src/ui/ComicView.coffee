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
    div(null, "Loading...")

module.exports = ComicView
