React = require 'react'
DOM = require 'react-dom'
{div, img} = require './tags'

class IndexEntry extends React.Component
  constructor: (props) ->
    super props

  style:
    display: 'inline-block'
    width: '150px'
    textAlign: 'center'
    margin: '10px'
    verticalAlign: 'top'

  render: ->
    text = @props.data.dir
    if @props.data.pages
      text += ", #{@props.data.pages} pages"
    image = img { src: "#{@props.data.dir}/cover.png" }
    return div { style: @style }, [image, text]

class IndexView extends React.Component
  @defaultProps:
    manifest: null

  constructor: (props) ->
    super props
    @state =
      dir: ""

  render: ->
    if not @props.manifest
      return div null, "Loading..."

    listing = @props.manifest.children[@state.dir]

    entries = []
    for entry in listing
      entries.push React.createElement(IndexEntry, { key: entry.dir, data: entry })
    return div(null, entries)

module.exports = IndexView
