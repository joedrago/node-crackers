React = require 'react'
DOM = require 'react-dom'
{a, div, img, span} = require '../tags'

class BrowseEntry extends React.Component
  constructor: (props) ->
    super props

  render: ->
    cover = img {
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

    link = a {
      key: 'link'
      href: link
      style:
        cursor: 'pointer'
    }, [
      cover
      title
    ]

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
