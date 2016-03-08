React = require 'react'
DOM = require 'react-dom'
ComicView = require './ComicView'
IndexView = require './IndexView'
{div, el} = require './tags'

injectTapEventPlugin = require "react-tap-event-plugin"
injectTapEventPlugin()

# FlatButton = require 'material-ui/lib/flat-button'
FontIcon = require 'material-ui/lib/font-icon'
IconButton = require 'material-ui/lib/icon-button'
LeftNav = require 'material-ui/lib/left-nav'
MenuItem = require 'material-ui/lib/menus/menu-item'
# RaisedButton = require 'material-ui/lib/raised-button'
Toolbar = require 'material-ui/lib/toolbar/toolbar'
ToolbarGroup = require 'material-ui/lib/toolbar/toolbar-group'
# ToolbarSeparator = require 'material-ui/lib/toolbar/toolbar-separator'
ToolbarTitle = require 'material-ui/lib/toolbar/toolbar-title'

class App extends React.Component
  @defaultProps:
    start: 0

  constructor: (props) ->
    super props
    @state =
      view: 'index'
      manifest: null
      navOpen: false

    @loadManifest()

  loadManifest: ->
    $.getJSON 'manifest.crackers', null, (manifest, status) =>
      @setState { manifest: manifest }

  render: ->
    view = switch @state.view
      when 'comic'
        el ComicView
      else
        el IndexView, { key: 'indexview', manifest: @state.manifest }

    return div null, [
      # Left navigation panel
      el LeftNav, {
        docked: false
        open: @state.navOpen
        onRequestChange: (open) => @setState { navOpen: open }
      }, [
        el MenuItem, {
          primaryText: "Home"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'home'
          onTouchTap: => @setState { view: 'index' }
        }
        el MenuItem, {
          primaryText: "Updates"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'event_note'
          onTouchTap: => @setState { view: 'comic' }
        }
        el MenuItem, {
          primaryText: "Search"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'search'
        }
      ]

      # Top toolbar
      el Toolbar, { key: 'toolbar' }, [
        el ToolbarGroup, { firstChild: true, float: 'left' }, [
          el IconButton, {
            iconClassName:"material-icons"
            onMouseUp: => @setState { navOpen: !@state.navOpen }
          }, 'menu'
        ]

        el ToolbarGroup, { float: 'right' }, [
          el ToolbarTitle, { text: "GD Comics" }
        ]
      ]

      view
    ]

module.exports = App
