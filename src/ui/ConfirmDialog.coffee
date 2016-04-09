# React
React = require 'react'
DOM = require 'react-dom'
Dimensions = require 'react-dimensions'
PubSub = require 'pubsub-js'

# Material UI components
Dialog = require 'material-ui/lib/dialog'
FlatButton = require 'material-ui/lib/flat-button'
RaisedButton = require 'material-ui/lib/raised-button'

# Local requires
{div, el} = require './tags'

class ConfirmDialog extends React.Component
  @defaultProps: {
    title: ''
    label: ''
    no: 'Cancel'
    yes: 'Confirm'
  }

  constructor: (props) ->
    super props

  handleClose: (confirmed = false) ->
    @props.cb(confirmed)

  render: ->
    actions = [
      el FlatButton, {
        label: @props.no
        secondary: true
        onTouchTap: => @handleClose()
      }
      el FlatButton, {
        label: @props.yes
        primary: true
        # keyboardFocused: true
        onTouchTap: => @handleClose(true)
      }
    ]

    return el Dialog, {
      title: @props.title
      actions: actions
      modal: false
      open: @props.open
      onRequestClose: => @handleClose()
    }, [
      @props.text
    ]

module.exports = ConfirmDialog
