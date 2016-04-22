React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'

Checkbox = require 'material-ui/lib/checkbox'
MenuItem = require 'material-ui/lib/menus/menu-item'
SelectField = require 'material-ui/lib/select-field'

Settings = require '../Settings'
{el, div, hr, img} = require '../tags'

class SettingsView extends React.Component
  constructor: (props) ->
    super props
    @state =
      kick: 0

  kick: ->
    @setState { kick: @state.kick + 1 }
    return

  toggle: (name) ->
    Settings.set(name, not Settings.getBool(name))
    @kick()
    return

  createCheckbox: (name, description) ->
    return el Checkbox, {
      key: "settings.#{name}"
      checked: Settings.getBool(name)
      label: description
      onCheck: => @toggle(name)
    }

  createZoombox: (name, value, enabled, description) ->
    selectField = el SelectField, {
        key: "zoombox.#{name}"
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

  createAutotouch: ->
    selectField = el SelectField, {
        value: Settings.getFloat('comic.autotouch')
        onChange: (event, index, value) =>
          Settings.set('comic.autotouch', value)
          @kick()
      }, [
        el MenuItem, { value:   0, primaryText: 'Disabled' }
        el MenuItem, { value: 1.5, primaryText: '1.5x' }
        el MenuItem, { value:   2, primaryText: '2x' }
      ]

    return div {}, [selectField]

  miniTitleStyle: ->
    return {
      color: '#aaaaaa'
      fontSize: '1.1em'
      fontStyle: 'italic'
      marginTop: '20px'
      marginBottom: '5px'
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

    # ------------------------------------------------------------------------

    elements.push @createCheckbox('comic.animation', "Enable comic animation")
    elements.push @createCheckbox('comic.showPageNumber', "Display the page number when switching pages")
    elements.push @createCheckbox('comic.confirmBinge', "Display confirmation dialog when auto-switching to the next/previous issue")
    elements.push @createCheckbox('comic.spaceAutoRead', "Space bar performs Autoread (vs simply 'next page')")
    elements.push @createCheckbox('updates.detailed', "Show detailed view when listing all dates in Updates")

    # ------------------------------------------------------------------------

    elements.push div {
      key: 'settings.zoomlevelstitle'
      style: @miniTitleStyle()
    }, "Zoom levels on double click/tap:"

    zoom1 = Settings.getFloat("comic.dblzoom1")
    zoom2 = Settings.getFloat("comic.dblzoom2")
    zoom3 = Settings.getFloat("comic.dblzoom3")
    if zoom1 == 0
      zoom2 = 0
      zoom3 = 0
    if zoom2 == 0
      zoom3 = 0

    elements.push @createZoombox('comic.dblzoom1', zoom1, true, "zoom1")
    elements.push @createZoombox('comic.dblzoom2', zoom2, (zoom1 > 0), "zoom2")
    elements.push @createZoombox('comic.dblzoom3', zoom3, (zoom2 > 0), "zoom3")

    # ------------------------------------------------------------------------

    elements.push hr {
      key: "hr.touchonly"
      size: 1
      style:
        marginTop: '20px'
        marginBottom: '20px'
        borderColor: '#777777'
    }

    # ------------------------------------------------------------------------

    elements.push div {
      key: 'settings.touchonly'
      style: @miniTitleStyle()
    }, "Touch devices only (tablet / phone):"

    elements.push @createCheckbox('fullscreen.overlay', "Force fullscreen mode with fullscreen overlay (when not in fullscreen)")
    elements.push @createCheckbox('comic.autoZoomOut', "Automatically unzoom when you aren't touching the screen")
    elements.push @createCheckbox('comic.zoomgrid', "Use zoomgrid")

    elements.push div {
      key: 'settings.autotouchtitle'
      style: @miniTitleStyle()
    }, "Enable autoread in landscape mode (touch devices only, choose scale):"
    elements.push @createAutotouch()

    # ------------------------------------------------------------------------

    view = div {
      style:
        marginTop: '10px'
        marginLeft: '60px'
    }, elements
    return view

module.exports = SettingsView
