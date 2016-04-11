React = require 'react'
{el, div, img, span} = require '../tags'

MarkdownSpan = require '../MarkdownSpan'

class WelcomeView extends React.Component
  constructor: (props) ->
    super props

  render: ->
    div {
      style:
        marginLeft: '2%'
        marginRight: '2%'
        marginTop: '40px'
        padding: '1%'
        color: '#ffffff'
        fontFamily: 'Roboto, sans-serif'
    }, el MarkdownSpan, {
      name: 'welcome'
    }

module.exports = WelcomeView
