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
    }, @props.info.dir.replace(/\//g, " | ")

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
      when 'comic'
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
    dir: null
    list: []
    onChangeDir: -> console.log "IndexView.onChangeDir: Ignored"

  constructor: (props) ->
    super props

  click: (info) ->
    if @props.onChangeDir
      @props.onChangeDir(info.dir)

  render: ->
    entries = []
    for entry in @props.list
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
        textAlign: 'center'
    }, entries

    return view

module.exports = IndexView
