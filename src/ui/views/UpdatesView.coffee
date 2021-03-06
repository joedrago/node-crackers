# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
Settings = require '../Settings'
{PlaceholderImage} = require './BrowseView'

# Local requires
tags = require '../tags'
{el} = require '../tags'

class UpdateDay extends React.Component
  constructor: (props) ->
    super props

  render: ->
    titleMarginBottom = '0px'
    if @props.detailed
      titleMarginBottom = '20px'

    title = tags.div {
      key: "day.title.#{@props.day.date}"
      style:
        marginTop: '10px'
        marginBottom: titleMarginBottom
    }, tags.a {
      key: "link"
      href: "#updates/#{@props.day.date}"
      style:
        color: '#ffaaff'
    }, @props.day.pdate

    links = []
    for e,index in @props.day.list
      text = [
        tags.span {
          key: "dir"
        }, e.title
      ]
      if e.hasOwnProperty('start')
        rangeText = " #{e.start}"
        if e.start != e.end
          rangeText += "-#{e.end}"
        text.push tags.span {
          key: 'range'
          style:
            color: '#aaffff'
        }, rangeText

      linkContents = text
      linkMarginLeft = '20px'
      outerStyle =
        marginLeft: '20px'
      if @props.detailed
        linkMarginLeft = '0px'
        outerStyle.display = 'inline-block'
        outerStyle.width = '150px'
        outerStyle.textAlign = 'center'
        outerStyle.marginLeft = '0px'
        outerStyle.marginLeft = '10px'
        outerStyle.marginRight = '10px'
        outerStyle.verticalAlign = 'top'
        linkContents = [
          el PlaceholderImage, {
            key: 'cover'
            src: e.cover
            style:
              display: 'block'
          }
          el 'br'
        ].concat text

      link = tags.div {
        key: "day.link.#{@props.day.date}.#{index}"
        style: outerStyle
      }, tags.a {
        key: "link"
        href: "##{e.action}/" + encodeURIComponent("#{e.dir}").replace("%2F", "/")
        style:
          color: '#ffffaa'
          marginLeft: linkMarginLeft
      }, linkContents

      links.push link

    return tags.div {
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

    days.push tags.a {
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

    view = tags.div {
      style:
        marginTop: '10px'
        marginLeft: '60px'
    }, days

    return view

module.exports = UpdatesView

'globals: UpdateDay'
