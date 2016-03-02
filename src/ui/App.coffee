React = require 'react'
DOM = require 'react-dom'
{div, h1} = require './tags'

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
    div(null, "count: #{@state.count}")

module.exports = App
