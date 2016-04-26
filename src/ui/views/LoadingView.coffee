# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'

# Local requires
{el} = require '../tags'

class LoadingView extends React.Component
  @defaultProps:
    dir: '.'

  constructor: (props) ->
    super props
    @state =
      dir: props.dir

  render: ->
    el Loader, {
      color: '#444444'
    }

module.exports = LoadingView
