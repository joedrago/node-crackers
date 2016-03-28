React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
{el, div, img} = require '../tags'

class SearchView extends React.Component
  constructor: (props) ->
    super props

  render: ->
    div {
      style:
        color: '#ffffff'
    }, "Search '#{@props.arg}'"

module.exports = SearchView
