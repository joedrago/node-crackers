React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'

Checkbox = require 'material-ui/lib/checkbox'

Settings = require '../Settings'
{el, div, img} = require '../tags'

class SettingsView extends React.Component
  constructor: (props) ->
    super props
    @state =
      kick: 0

  toggle: (name, defaultValue) ->
    Settings.set(name, not Settings.getBool(name, defaultValue))
    @setState { kick: @state.kick + 1 }
    return

  createCheckbox: (name, defaultValue, description) ->
    return el Checkbox, {
      key: "settings.#{name}"
      checked: Settings.getBool(name, defaultValue)
      label: "Automatically unzoom when you aren't touching the screen (only use on tablets/phones)"
      onCheck: => @toggle(name, defaultValue)
    }

  render: ->
    elements = []

    elements.push div {
      key: 'settings.title'
      style:
        color: '#aaaaaa'
        fontSize: '1.2em'
        fontStyle: 'italic'
        marginBottom: '15px'
    }, "Settings"

    elements.push @createCheckbox('comic.autoZoomOut', false, "Automatically unzoom when you aren't touching the screen (only use on tablets/phones)")

    view = div {
      style:
        marginTop: '10px'
        marginLeft: '60px'
    }, elements

    return view

module.exports = SettingsView
