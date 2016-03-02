React = require 'react'
DOM = require 'react-dom'
ComicView = require './ComicView'
{div} = require './tags'

class App extends React.Component
  @defaultProps:
    start: 1

  constructor: (props) ->
    super props
    @state =
      count: props.start

    setInterval(=>
      @setState({ count: @state.count + 1 })
    , 3000)

  render: ->
    React.createElement(ComicView, { src: 'cover.png' })

module.exports = App
