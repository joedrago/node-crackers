React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
{a, el, div, img, span} = require '../tags'

class UpdateDay extends React.Component
  constructor: (props) ->
    super props

  render: ->
    title = div {
      key: "day.title.#{@props.day.date}"
      style:
        color: '#ffaaff'
        marginTop: '10px'
    }, @props.day.date

    links = []
    for e,index in @props.day.list
      action = 'comic'

      text = [
        span {
          key: "dir"
        }, e.dir
      ]
      if e.hasOwnProperty('start')
        action = 'browse'
        rangeText = " #{e.start}"
        if e.start != e.end
          rangeText += "-#{e.end}"
        text.push span {
          key: 'range'
          style:
            color: '#aaffff'
        }, rangeText

      link = div {
        key: "day.link.#{@props.day.date}.#{index}"
      }, a {
        key: "link"
        href: "##{action}/" + encodeURIComponent("#{e.dir}").replace("%2F", "/")
        style:
          color: '#ffffaa'
          marginLeft: '20px'
      }, text

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

    days.push div {
      key: 'updates.title'
      style:
        color: '#aaaaaa'
        fontSize: '1.2em'
        fontStyle: 'italic'
    }, "Updates"

    for day in @state.updates
      days.push el UpdateDay, {
        key: "update.#{day.date}"
        day: day
      }

    view = div {
      style:
        marginTop: '10px'
        marginLeft: '60px'
    }, days

    return view

module.exports = UpdatesView
