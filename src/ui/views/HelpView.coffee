# React
React = require 'react'

# Local requires
tags = require '../tags'
{el} = require '../tags'

MarkdownSpan = require '../MarkdownSpan'
Settings = require '../Settings'

class HelpView extends React.Component
  constructor: (props) ->
    super props

  render: ->
    Settings.set('help.reminder', 'false')
    tags.div {
      id: 'help'
      style:
        display: 'inline-block'
        marginLeft: '10px'
        marginRight: '10px'
        marginTop: '45px'
        padding: '5px'
        maxWidth: '650px'
    }, el MarkdownSpan, {
      name: 'help'
    }

module.exports = HelpView
