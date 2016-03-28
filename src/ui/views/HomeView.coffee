React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
{el, div, img} = require '../tags'

class HomeView extends React.Component
  constructor: (props) ->
    super props

  render: ->
    div {
      style:
        color: '#ffffff'
    }, "Home '#{@props.arg}'"

module.exports = HomeView
