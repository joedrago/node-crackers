React = require 'react'
DOM = require 'react-dom'
{a, div, el, img, span} = require '../tags'

COVER_WIDTH = '150px'
COVER_HEIGHT = '231px' # placeholder height, the real images are auto-height

class PlaceholderImage extends React.Component
  constructor: (props) ->
    super props
    @state =
      loaded: false

  onLoad: ->
    @setState { loaded: true }

  componentDidMount: ->
    @image = new Image()
    @image.onload = @onLoad.bind(this)
    @image.src = @props.src

  render: ->
    if @state.loaded
      return img {
        key: @props.key
        src: @props.src
      }

    return div {
      key: @props.key
      style:
        display: 'block'
        width: COVER_WIDTH
        height: COVER_HEIGHT
        background: '#333355'
    }

class BrowseEntry extends React.Component
  constructor: (props) ->
    super props

  render: ->
    cover = el PlaceholderImage, {
      key: 'cover'
      src: "#{@props.info.dir}/cover.png"
    }

    switch @props.info.type
      when 'comic'
        link = "#comic/#{@props.info.dir}"
        subtitleText = "(#{@props.info.pages} pages)"
      when 'index'
        link = "#browse/#{@props.info.dir}"
        subtitleText = "(#{@props.info.count} comics, Newest: #{@props.info.recent})"

    title = span {
      key: 'title'
      style:
        fontWeight: 900
        color: '#ffffff'
    }, @props.info.dir.replace(/\//g, " | ")

    linkContents = [ cover ]

    if @props.info.hasOwnProperty('perc')
      percent = @props.info.perc
      if percent < 0
        percent = 0
      progressBar = div {
        style:
          display: 'block'
          width: COVER_WIDTH
          height: '10px'
          marginBottom: '3px'
          background: '#333333'
      }, [
        div {
          style:
            width: "#{percent}%"
            height: '100%'
            background: '#669966'
        }
      ]
      linkContents.push progressBar

    linkContents.push title

    link = a {
      key: 'link'
      href: link
      style:
        cursor: 'pointer'
    }, linkContents

    subtitle = div {
      key: 'subtitle'
      style:
        color: '#aaaaaa'
        fontSize: '0.7em'
    }, subtitleText

    entry = div {
      style:
        display: 'inline-block'
        width: COVER_WIDTH
        textAlign: 'center'
        margin: '10px'
        verticalAlign: 'top'
    }, [
      link
      subtitle
    ]
    return entry

class BrowseView extends React.Component
  constructor: (props) ->
    super props

  click: (info) ->
    # if @props.onChangeDir
    #   @props.onChangeDir(info.dir)

  render: ->
    if not @props.manifest.children.hasOwnProperty(@props.arg)
      return div {
        style:
          color: '#ffffff'
      }, "Invalid directory. Go home."

    list = @props.manifest.children[@props.arg]
    entries = []
    for entry in list
      entryElement = React.createElement BrowseEntry, {
        key: entry.dir
        info: entry
      }
      entries.push entryElement

    view = div {
      style:
        width: '100%'
        height: '100%'
        backgroundColor: '#111111'
        textAlign: 'center'
    }, entries

    return view

module.exports = BrowseView
