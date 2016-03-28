# React
React = require 'react'
DOM = require 'react-dom'
Dimensions = require 'react-dimensions'
PubSub = require 'pubsub-js'

# Local requires
LRUCache = require './LRUCache'
{div, el} = require './tags'

# Views
BrowseView = require './views/BrowseView'
ComicView = require './views/ComicView'
HelpView = require './views/HelpView'
HomeView = require './views/HomeView'
LoadingView = require './views/LoadingView'
SearchView = require './views/SearchView'
SettingsView = require './views/SettingsView'
UpdatesView = require './views/UpdatesView'

# Material UI components
AppBar = require 'material-ui/lib/app-bar'
FlatButton = require 'material-ui/lib/flat-button'
Divider = require 'material-ui/lib/divider'
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

  constructor: (props) ->
    super props

    @comicMetadataCache = new LRUCache(100)
    @progressEnabled = "#inject{progress}" == "true"
    @state =
      navOpen: false
      manifest: null
      view: 'home'
      viewArg: ''
      dir: ''
      comicMetadata: null
      indexList: null

    @views =
      home: HomeView
      browse: BrowseView
      comic: ComicView
      help: HelpView
      search: SearchView
      settings: SettingsView
      updates: UpdatesView

    @loadManifest()

    $(document).keydown (event) =>
      @onKeyDown(event)
      return true

    @navigate(true)
    window.addEventListener('hashchange', (event) =>
      @navigate()
    , false)

  loadManifest: ->
    $.getJSON '#inject{endpoint}', null, (manifest, status) =>
      @setState {
        manifest: manifest
      }
      # @changeDir(@state.dir)

  redirect: (newHash) ->
    window.location.replace(window.location.pathname + window.location.search + newHash)
    return

  navigate: (fromConstructor = false) ->
    newHash = window.location.hash.replace(/^#\/?|\/$/g, '')
    view = newHash.split('/')[0]
    viewArg = newHash.substring(view.length+1)
    if not @views.hasOwnProperty(view)
      view = 'home'
      viewArg = ''
      @redirect('#home')

    console.log "navigate('#{view}', '#{viewArg}')"
    if fromConstructor
      @state.view = view
      @state.viewArg = viewArg
    else
      @setState { view: view, viewArg: viewArg }

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
    elements = [
      # Corner icon
      el IconButton, {
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 0
            top: 0
            zIndex: 1
          onTouchTap: =>
            @setState { navOpen: !@state.navOpen }
        }, 'keyboard_arrow_right'
    ]

    # Left navigation panel
    navMenuItems = [
      el MenuItem, {
        primaryText: "Home"
        leftIcon: el FontIcon, { className: 'material-icons' }, 'home'
        onTouchTap: =>
          @redirect('#home')
          @setState { navOpen: false }
      }
      el MenuItem, {
        primaryText: "Browse"
        leftIcon: el FontIcon, { className: 'material-icons' }, 'grid_on'
        onTouchTap: =>
          @redirect('#browse')
          @setState { navOpen: false }
      }
      el MenuItem, {
        primaryText: "Updates"
        leftIcon: el FontIcon, { className: 'material-icons' }, 'event_note'
        onTouchTap: =>
          @redirect('#updates')
          @setState { navOpen: false }
      }
      el MenuItem, {
        primaryText: "Search"
        leftIcon: el FontIcon, { className: 'material-icons' }, 'search'
        onTouchTap: =>
          @redirect('#search')
          @setState { navOpen: false }
      }
      el MenuItem, {
        primaryText: "Settings"
        leftIcon: el FontIcon, { className: 'material-icons' }, 'settings'
        onTouchTap: =>
          @redirect('#settings')
          @setState { navOpen: false }
      }
      el MenuItem, {
        primaryText: "Help"
        leftIcon: el FontIcon, { className: 'material-icons' }, 'help'
        onTouchTap: =>
          @redirect('#help')
          @setState { navOpen: false }
      }
    ]

    if false
      navMenuItems.push(el Divider)
      navMenuItems.push(
        el MenuItem, {
          primaryText: "Next Issue in Series"
          leftIcon: el FontIcon, { className: 'material-icons' }, 'skip_next'
        }
      )

    elements.push(el LeftNav, {
        docked: false
        open: @state.navOpen
        swipeAreaWidth: 50
        onRequestChange: (open) => @setState { navOpen: open }
      }, navMenuItems
    )

    if @state.manifest
      # console.log "chose view #{@state.view}"
      view = el @views[@state.view], {
        width: @props.containerWidth
        height: @props.containerHeight
        manifest: @state.manifest
        arg: @state.viewArg
      }
    else
      view = el LoadingView

    elements.push view
    return div { id: 'outerdiv' }, elements

module.exports = Dimensions()(App)
