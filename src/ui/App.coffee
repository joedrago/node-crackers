React = require 'react'
DOM = require 'react-dom'
IndexView = require './IndexView'
{div} = require './tags'

class App extends React.Component
  @defaultProps:
    start: 0

  constructor: (props) ->
    super props
    @state =
      manifest: null

    @loadManifest()

  loadManifest: ->
    $.getJSON 'manifest.crackers', null, (manifest, status) =>
      @setState { manifest: manifest }

  render: ->
    React.createElement(IndexView, { manifest: @state.manifest })

module.exports = App
