React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
Settings = require '../Settings'
{PlaceholderImage} = require './BrowseView'
{a, el, div, img, span} = require '../tags'

class UpdateDay extends React.Component
  constructor: (props) ->
    super props

  render: ->
    titleMarginBottom = '0px'
    if @props.detailed
      titleMarginBottom = '20px'

    title = div {
      key: "day.title.#{@props.day.date}"
      style:
        marginTop: '10px'
        marginBottom: titleMarginBottom
    }, a {
      key: "link"
      href: "#updates/#{@props.day.date}"
      style:
        color: '#ffaaff'
    }, @props.day.pdate

    links = []
    for e,index in @props.day.list
      text = [
        span {
          key: "dir"
        }, e.title
      ]
      if e.hasOwnProperty('start')
        rangeText = " #{e.start}"
        if e.start != e.end
          rangeText += "-#{e.end}"
        text.push span {
          key: 'range'
          style:
            color: '#aaffff'
        }, rangeText

      linkContents = text
      outerDisplay = 'block'
      outerTextAlign = 'left'
      outerHorizMargin = '0px'
      linkMarginLeft = '20px'
      if @props.detailed
        outerDisplay = 'inline-block'
        outerTextAlign = 'center'
        linkMarginLeft = '0px'
        outerHorizMargin = '10px'
        linkContents = [
          el PlaceholderImage, {
            key: 'cover'
            src: e.cover
            style:
              display: 'block'
          }
          el 'br'
        ].concat text

      link = div {
        key: "day.link.#{@props.day.date}.#{index}"
        style:
          display: outerDisplay
          textAlign: outerTextAlign
          marginLeft: outerHorizMargin
          marginRight: outerHorizMargin
      }, a {
        key: "link"
        href: "##{e.action}/" + encodeURIComponent("#{e.dir}").replace("%2F", "/")
        style:
          color: '#ffffaa'
          marginLeft: linkMarginLeft
      }, linkContents

      links.push link

    return div {
      style:
        color: '#ffaaff'
        fontFamily: 'monospace'
        fontSize: '1.1em'
    }, [
      title
      links
    ]


class UpdatesView extends React.Component
  constructor: (props) ->
    super props
    @state =
      updates: null

  loadUpdates: ->
    ajaxData = {
      url: 'updates.crackers'
      dataType: 'json'
      data: null
      success: (updates, status) =>
        # console.log updates
        @setState {
          updates: updates
        }
    }
    $.ajax ajaxData

  componentWillMount: ->
    @loadUpdates()

  render: ->
    if not @state.updates
      return el Loader, {
        key: "updates.loading"
      }

    days = []

    days.push a {
      key: 'updates.title'
      href: '#updates'
      style:
        display: 'block'
        color: '#aaaaaa'
        fontSize: '1.2em'
        fontStyle: 'italic'
    }, "Updates"

    specificDate = null
    for day in @state.updates
      if day.date == @props.arg
        specificDate = @props.arg
        break

    showDetailed = (specificDate != null) or Settings.getBool('updates.detailed')
    for day in @state.updates
      if (specificDate == null) or (day.date == specificDate)
        days.push el UpdateDay, {
          key: "update.#{day.date}"
          day: day
          detailed: showDetailed
        }

    view = div {
      style:
        marginTop: '10px'
        marginLeft: '60px'
    }, days

    return view

module.exports = UpdatesView
