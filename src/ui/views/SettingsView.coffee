React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'

Checkbox = require 'material-ui/lib/checkbox'
MenuItem = require 'material-ui/lib/menus/menu-item'
SelectField = require 'material-ui/lib/select-field'

Settings = require '../Settings'
{el, div, img} = require '../tags'

class SettingsView extends React.Component
  constructor: (props) ->
    super props
    @state =
      kick: 0

  kick: ->
    @setState { kick: @state.kick + 1 }
    return

  toggle: (name, defaultValue) ->
    Settings.set(name, not Settings.getBool(name, defaultValue))
    @kick()
    return

  createCheckbox: (name, defaultValue, description) ->
    return el Checkbox, {
      key: "settings.#{name}"
      checked: Settings.getBool(name, defaultValue)
      label: "Automatically unzoom when you aren't touching the screen (only use on tablets/phones)"
      onCheck: => @toggle(name, defaultValue)
    }

  createZoombox: (name, value, enabled, description) ->
    selectField = el SelectField, {
        value: value
        disabled: !enabled
        onChange: (event, index, value) =>
          console.log "changing #{name} to #{value}"
          Settings.set(name, value)
          @kick()
      }, [
        el MenuItem, { value:   0, primaryText: 'Disabled' }
        el MenuItem, { value: 1.5, primaryText: '1.5x' }
        el MenuItem, { value:   2, primaryText: '2x' }
        el MenuItem, { value: 2.5, primaryText: '2.5x' }
        el MenuItem, { value:   3, primaryText: '3x' }
      ]

    return div {}, [selectField]

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

    elements.push div {
      key: 'settings.zoomlevelstitle'
      style:
        color: '#aaaaaa'
        fontSize: '1.1em'
        fontStyle: 'italic'
        marginTop: '20px'
        marginBottom: '5px'
    }, "Zoom levels when double clicked:"

    zoom1 = Settings.getFloat("comic.dblzoom1", 2)
    zoom2 = Settings.getFloat("comic.dblzoom2", 3)
    zoom3 = Settings.getFloat("comic.dblzoom3", 0)
    if zoom1 == 0
      zoom2 = 0
      zoom3 = 0
    if zoom2 == 0
      zoom3 = 0

    elements.push @createZoombox('comic.dblzoom1', zoom1, true, "zoom1")
    elements.push @createZoombox('comic.dblzoom2', zoom2, (zoom1 > 0), "zoom2")
    elements.push @createZoombox('comic.dblzoom3', zoom3, (zoom2 > 0), "zoom3")

    view = div {
      style:
        marginTop: '10px'
        marginLeft: '60px'
    }, elements

    return view

module.exports = SettingsView
