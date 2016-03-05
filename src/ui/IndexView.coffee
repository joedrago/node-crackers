React = require 'react'
DOM = require 'react-dom'
{a, div, img, span} = require './tags'

class IndexEntry extends React.Component
  constructor: (props) ->
    super props

  render: ->
    cover = img {
      key: 'cover'
      src: "#{@props.info.dir}/cover.png"
    }

    title = span {
      key: 'title'
      style:
        fontWeight: 900
        color: '#ffffff'
    }, @props.info.dir

    link = a {
      key: 'link'
      onClick: => @props.click(@props.info)
      style:
        cursor: 'pointer'
    }, [
      cover
      title
    ]

    switch @props.info.type
      when 'issue'
        subtitleText = "(#{@props.info.pages} pages)"
      when 'index'
        subtitleText = "(#{@props.info.count} comics, Newest: #{@props.info.recent})"

    subtitle = div {
      key: 'subtitle'
      style:
        color: '#aaaaaa'
        fontSize: '0.7em'
    }, subtitleText

    entry = div {
      style:
        display: 'inline-block'
        width: '150px'
        textAlign: 'center'
        margin: '10px'
        verticalAlign: 'top'
    }, [
      link
      subtitle
    ]
    return entry

class IndexView extends React.Component
  @defaultProps:
    manifest: null

  constructor: (props) ->
    super props
    @state =
      dir: ""

  click: (info) ->
    if info.type == 'index'
      @setState { dir: info.dir }
    else
      @setState { dir: "" }

  render: ->
    if not @props.manifest
      return div {
        style:
          backgroundColor: '#110000'
      }, "Loading..."

    listing = @props.manifest.children[@state.dir]

    entries = []
    for entry in listing
      entryElement = React.createElement IndexEntry, {
        key: entry.dir
        info: entry
        click: (info) => @click(info)
      }
      entries.push entryElement

    view = div {
      style:
        width: '100%'
        height: '100%'
        backgroundColor: '#111111'
    }, entries

    return view

module.exports = IndexView
