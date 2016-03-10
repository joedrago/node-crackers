# React
React = require 'react'
DOM = require 'react-dom'
Dimensions = require 'react-dimensions'
PubSub = require 'pubsub-js'

# Local requires
ComicView = require './ComicView'
IndexView = require './IndexView'
LoadingView = require './LoadingView'
LRUCache = require './LRUCache'
{div, el} = require './tags'

# Material UI components
AppBar = require 'material-ui/lib/app-bar'
FlatButton = require 'material-ui/lib/flat-button'
FontIcon = require 'material-ui/lib/font-icon'
IconButton = require 'material-ui/lib/icon-button'
LeftNav = require 'material-ui/lib/left-nav'
MenuItem = require 'material-ui/lib/menus/menu-item'
RaisedButton = require 'material-ui/lib/raised-button'
Toolbar = require 'material-ui/lib/toolbar/toolbar'
ToolbarGroup = require 'material-ui/lib/toolbar/toolbar-group'
ToolbarSeparator = require 'material-ui/lib/toolbar/toolbar-separator'
ToolbarTitle = require 'material-ui/lib/toolbar/toolbar-title'

# Material UI theming
DarkTheme = require 'material-ui/lib/styles/baseThemes/darkBaseTheme'
getMuiTheme = require 'material-ui/lib/styles/getMuiTheme'

# React requirement, should go away in the future
injectTapEventPlugin = require "react-tap-event-plugin"
injectTapEventPlugin()

class App extends React.Component
  # Enables the "Dark" theme
  @childContextTypes: { muiTheme: React.PropTypes.object }
  getChildContext: -> { muiTheme: getMuiTheme(DarkTheme) }

  @defaultProps:
    start: 0

  constructor: (props) ->
    super props
    @comicMetadataCache = new LRUCache(100)
    @state =
      navOpen: false
      manifest: null
      view: 'comics'
      dir: ''
      comicMetadata: null
      indexList: null

    @loadManifest()
    $(document).keydown (event) =>
      @onKeyDown(event)

  loadManifest: ->
    $.getJSON 'manifest.crackers', null, (manifest, status) =>
      @setState {
        manifest: manifest
      }
      @changeDir(@state.dir)

  changeDir: (dir) ->
    console.log "changeDir(#{dir})"
    comicMetadata = null
    indexList = @state.manifest.children[dir]
    if not indexList
      console.log "loading comic: #{dir}"
      indexList = null
      comicMetadata = @comicMetadataCache.get(dir)
      if comicMetadata
        console.log "using cached metadata: #{dir}"
        @setState {
          comicMetadata: comicMetadata
        }
      else
        metadataUrl = "#{dir}/meta.crackers"
        console.log "Downloading #{metadataUrl}"
        metadataDir = dir
        $.getJSON(metadataUrl)
        .success (metadata) =>
          @comicMetadataCache.put metadataDir, metadata
          @setState {
            comicMetadata: metadata
          }
        .error ->
          console.log "lel error!"

    @setState {
      dir: dir
      indexList: indexList
      comicMetadata: comicMetadata
    }

  onKeyDown: (event) ->
    # console.log "App.onKeyDown"
    if event.keyCode == 32
      @setState { navOpen: !@state.navOpen }
    PubSub.publish('key', event)

  render: ->
    view = null
    if @state.manifest and (@state.view == 'comics')
      if @state.indexList
        console.log "choosing IndexView"
        view = el IndexView, {
          key: 'indexview'
          list: @state.manifest.children[@state.dir]
          onChangeDir: (dir) => @changeDir(dir)
        }
      else if @state.comicMetadata
        console.log "choosing ComicView"
        view = el ComicView, {
          metadata: @state.comicMetadata
          width: @props.containerWidth
          height: @props.containerHeight
        }

    if view == null
      console.log "choosing LoadingView"
      view = el LoadingView

    return div {
        id: 'outerdiv'
      }, [

      # Left navigation panel
      el LeftNav, {
        docked: false
        open: @state.navOpen
        onRequestChange: (open) => @setState { navOpen: open }
      }, [
        el MenuItem, {
          primaryText: "Home"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'home'
          onTouchTap: =>
            @changeDir('')
            @setState { navOpen: false }
        }
        el MenuItem, {
          primaryText: "Updates"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'event_note'
          onTouchTap: =>
        }
        el MenuItem, {
          primaryText: "Search"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'search'
        }
      ]

      # el AppBar, {
      #   title: "GD Comics"
      #   onLeftIconButtonTouchTap: => @setState { navOpen: !@state.navOpen }
      #   onTitleTouchTap: => @changeDir('')
      # }

      view
    ]

module.exports = Dimensions()(App)
