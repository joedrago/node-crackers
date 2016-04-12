# React
React = require 'react'
DOM = require 'react-dom'
Dimensions = require 'react-dimensions'
PubSub = require 'pubsub-js'

# Local requires
LRUCache = require './LRUCache'
ConfirmDialog = require './ConfirmDialog'
Settings = require './Settings'
fullscreen = require './fullscreen'
{div, el, icon} = require './tags'

# Views
BrowseView = require './views/BrowseView'
ComicView = require './views/ComicView'
HelpView = require './views/HelpView'
LoadingView = require './views/LoadingView'
SettingsView = require './views/SettingsView'
UpdatesView = require './views/UpdatesView'

# Material UI components
AppBar = require 'material-ui/lib/app-bar'
FlatButton = require 'material-ui/lib/flat-button'
Divider = require 'material-ui/lib/divider'
IconButton = require 'material-ui/lib/icon-button'
LeftNav = require 'material-ui/lib/left-nav'
MenuItem = require 'material-ui/lib/menus/menu-item'
RaisedButton = require 'material-ui/lib/raised-button'
Snackbar = require 'material-ui/lib/snackbar'
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

# Uncomment to enable profiling
# require './Profiling'

# ------------------------------------------------------------------------
# I guess Safari doesn't have Math.sign. So weird.

Math.sign = Math.sign || (x) ->
  x = +x # convert to a number
  if (x == 0) || isNaN(x)
    return x
  if x > 0
    return 1
  return -1

# ------------------------------------------------------------------------
# App

class App extends React.Component
  # Enables the "Dark" theme
  @childContextTypes: { muiTheme: React.PropTypes.object }
  getChildContext: -> { muiTheme: getMuiTheme(DarkTheme) }

  constructor: (props) ->
    super props

    @comicMetadataCache = new LRUCache(100)
    @pageUpdateTimer = null
    @state =
      navOpen: false
      helpSnackbarOpen: Settings.getBool('help.reminder')
      manifest: null
      view: 'home'
      viewArg: ''
      dir: ''
      comicMetadata: null
      indexList: null
      confirmCB: null
      fullscreen: fullscreen.available() and fullscreen.active()

    @views =
      browse: BrowseView
      comic: ComicView
      help: HelpView
      settings: SettingsView
      updates: UpdatesView

    @loadManifest()

    # Left navigation panel
    @navMenuItems = [
      el MenuItem, {
        key: "menu.browse"
        primaryText: "Browse"
        leftIcon: icon 'grid_on'
        onTouchTap: (e) =>
          e.preventDefault()
          @redirect('#browse')
          @setState { navOpen: false }
      }
      el MenuItem, {
        key: "menu.updates"
        primaryText: "Updates"
        leftIcon: icon 'event_note'
        onTouchTap: (e) =>
          e.preventDefault()
          @redirect('#updates')
          @setState { navOpen: false }
      }
      el MenuItem, {
        key: "menu.settings"
        primaryText: "Settings"
        leftIcon: icon 'settings'
        onTouchTap: (e) =>
          e.preventDefault()
          @redirect('#settings')
          @setState { navOpen: false }
      }
      el MenuItem, {
        key: "menu.help"
        primaryText: "Help"
        leftIcon: icon 'help'
        onTouchTap: (e) =>
          e.preventDefault()
          @redirect('#help')
          @setState { navOpen: false }
      }
    ]

    if fullscreen.available()
      @navMenuItems.push el Divider, {
        key: 'fulscreen_divider'
      }
      @navMenuItems.push el MenuItem, {
        key: "menu.fullscreen"
        primaryText: "Toggle Fullscreen"
        leftIcon: icon 'fullscreen'
        onTouchTap: (e) =>
          e.preventDefault()
          fullscreen.toggle()
          @setState { navOpen: false, fullscreen: fullscreen.active() }
      }

    $(document).keydown (event) =>
      @onKeyDown(event)
      return true

    @navigate(true)
    window.addEventListener('hashchange', (event) =>
      @navigate()
    , false)

  loadManifest: (updateData = null) ->
    ajaxData = {
      url: @props.endpoint
      dataType: 'json'
      data: null
      success: (manifest, status) =>
        # console.log manifest
        @setState {
          manifest: manifest
        }
    }
    if @props.progressEnabled and (updateData != null)
      ajaxData.data = JSON.stringify(updateData)
      ajaxData.type = 'POST'
    $.ajax ajaxData

  redirect: (newHash) ->
    # window.location.replace(window.location.pathname + window.location.search + newHash)
    window.location.hash = newHash
    return

  navigate: (fromConstructor = false) ->
    newHash = decodeURIComponent(window.location.hash.replace(/^#\/?|\/$/g, ''))
    view = newHash.split('/')[0]
    viewArg = newHash.substring(view.length+1)
    if not @views.hasOwnProperty(view)
      view = 'browse'
      viewArg = ''
      @redirect('#browse')

    # console.log "navigate('#{view}', '#{viewArg}')"
    if fromConstructor
      @state.view = view
      @state.viewArg = viewArg
    else
      @setState { view: view, viewArg: viewArg }

  changeDir: (dir) ->
    # console.log "changeDir(#{dir})"
    comicMetadata = null
    indexList = @state.manifest.children[dir]
    if not indexList
      # console.log "loading comic: #{dir}"
      indexList = null
      comicMetadata = @comicMetadataCache.get(dir)
      if comicMetadata
        # console.log "using cached metadata: #{dir}"
        @setState {
          comicMetadata: comicMetadata
        }
      else
        metadataUrl = "#{dir}/meta.crackers"
        # console.log "Downloading #{metadataUrl}"
        metadataDir = dir
        $.getJSON(metadataUrl)
        .success (metadata) =>
          @comicMetadataCache.put metadataDir, metadata
          @setState {
            comicMetadata: metadata
          }
        .error ->
          # console.log "lel error!"

    @setState {
      dir: dir
      indexList: indexList
      comicMetadata: comicMetadata
    }

  updatePageProgress: (dir, page) ->
    # console.log "[#{dir}] update page progress #{page}"
    @loadManifest({
      dir: dir
      page: page
    })

  dirAction: (dir, action) ->
    switch action
      when 'mark'
        yesText = "Mark As Read"
        title = "Confirmation!"
        text = "Mark '#{dir}' as Read?"
      when 'unmark'
        yesText = "Mark As Unread"
        title = "Confirmation!"
        text = "Mark '#{dir}' as Unread?"
      when 'ignore'
        yesText = "Toggle Ignore"
        title = "Confirmation!"
        text = "Toggle ignore on '#{dir}'?"
      else
        return

    @setState {
      confirmYes: yesText
      confirmTitle: title
      confirmText: text
      confirmCB: (confirmed) =>
        if not confirmed
          return
        # console.log "dirAction(#{dir}, #{action}) confirmed: #{confirmed}"
        updateData = switch action
          when 'mark'   then { mark:   dir }
          when 'unmark' then { unmark: dir }
          when 'ignore' then { ignore: dir }
          else null
        if updateData
          @loadManifest(updateData)
    }
    return

  onViewPage: (dir, page) ->
    if not @props.progressEnabled
      return

    # console.log "[#{dir}] displaying page #{page}"
    if @pageUpdateTimer != null
      clearTimeout(@pageUpdateTimer)
    @pageUpdateTimer = setTimeout =>
      @updatePageProgress(dir, page)
      @pageUpdateTimer = null
    , 1000

  onKeyDown: (event) ->
    # console.log "App.onKeyDown"

    # Space bar. Interferes with scrolling via space in Chrome
    # if event.keyCode == 32
    #   @setState { navOpen: !@state.navOpen }

    PubSub.publish('key', event)

  render: ->
    elements = [
      # Corner icon
      el IconButton, {
          key: "opennavbutton"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 0
            top: 0
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              @setState { navOpen: !@state.navOpen }
            , 0
        }, 'menu'

        el ConfirmDialog, {
          key: "confirmdialog"
          open: (@state.confirmCB != null)
          yes: @state.confirmYes
          title: @state.confirmTitle
          text: @state.confirmText
          cb: (confirmed) =>
            if @state.confirmCB
              @state.confirmCB(confirmed)
              @setState { confirmCB: null }
        }
    ]

    if fullscreen.available() and fullscreen.active()
      # Fake back button
      elements.push el IconButton, {
          key: "fakebackbutton"
          iconClassName: 'material-icons'
          touch: true
          style:
            opacity: 0.5
            position: 'fixed'
            left: 40
            top: 0
            zIndex: 2
          iconStyle:
            color: '#ffffff'
          onTouchTap: =>
            setTimeout =>
              window.history.back()
            , 0
        }, 'keyboard_arrow_left'

    elements.push(el LeftNav, {
        key: 'leftnav'
        docked: false
        open: @state.navOpen
        disableSwipeToOpen: true
        onRequestChange: (open) => @setState { navOpen: open }
      }, @navMenuItems
    )

    elements.push el Snackbar, {
      open: @state.helpSnackbarOpen
      message: 'First time here? Learn the basics!'
      action: 'Learn'
      autoHideDuration: 4000
      onActionTouchTap: =>
        @redirect('#help')
        @setState { helpSnackbarOpen: false }
      onRequestClose: =>
        @setState { helpSnackbarOpen: false }
    }

    if @state.manifest
      # console.log "chose view #{@state.view}"
      view = el @views[@state.view], {
        key: "view.#{@state.view}"
        progressEnabled: @props.progressEnabled
        width: @props.containerWidth
        height: @props.containerHeight
        manifest: @state.manifest
        arg: @state.viewArg

        onViewPage: (dir, page) =>
          @onViewPage(dir, page)
        dirAction: (dir, action) =>
          @dirAction(dir, action)
        redirect: (newHash) =>
          @redirect(newHash)
      }
    else
      view = el LoadingView, {
        key: "app.loadingview"
      }

    elements.push view
    return div { id: 'outerdiv' }, elements

module.exports = Dimensions()(App)
