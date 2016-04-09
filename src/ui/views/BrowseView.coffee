# React
React = require 'react'
DOM = require 'react-dom'

# Material UI components
DropDownMenu = require 'material-ui/lib/DropDownMenu'
FlatButton = require 'material-ui/lib/flat-button'
LeftNav = require 'material-ui/lib/left-nav'
IconButton = require 'material-ui/lib/icon-button'
IconMenu = require 'material-ui/lib/menus/icon-menu'
MenuItem = require 'material-ui/lib/menus/menu-item'
Toolbar = require 'material-ui/lib/toolbar/toolbar'
ToolbarGroup = require 'material-ui/lib/toolbar/toolbar-group'
ToolbarSeparator = require 'material-ui/lib/toolbar/toolbar-separator'
ToolbarTitle = require 'material-ui/lib/toolbar/toolbar-title'

# Local requires
Settings = require '../Settings'
{a, div, el, icon, img, hr, span} = require '../tags'

COVER_WIDTH = '150px'
COVER_HEIGHT = '231px' # placeholder height, the real images are auto-height

class PlaceholderImage extends React.Component
  constructor: (props) ->
    super props
    @state =
      loaded: false

  onLoad: ->
    @setState { loaded: true }

  componentDidMount: ->
    @image = new Image()
    @image.onload = @onLoad.bind(this)
    @image.src = @props.src

  render: ->
    if @state.loaded
      return img {
        key: @props.key
        src: @props.src
      }

    return div {
      key: @props.key
      style:
        display: 'block'
        width: COVER_WIDTH
        height: COVER_HEIGHT
        background: '#333355'
    }

class BrowseEntry extends React.Component
  constructor: (props) ->
    super props

  render: ->
    cover = el PlaceholderImage, {
      key: 'cover'
      src: "#{@props.info.dir}/cover.png"
    }

    switch @props.info.type
      when 'comic'
        href = "#comic/"+encodeURIComponent("#{@props.info.dir}").replace("%2F", "/")
        subtitleText = "(#{@props.info.pages} pages)"
      when 'index'
        href = "#browse/" + encodeURIComponent("#{@props.info.dir}").replace("%2F", "/")
        subtitleText = "(#{@props.info.count} comics, Newest: #{@props.info.recent})"

    title = span {
      key: 'title'
      style:
        fontWeight: 900
        color: '#ffffff'
    }, @props.info.dir.replace(/\//g, " | ")

    linkContents = []

    if @props.progressEnabled
      percent = @props.info.perc
      if percent < 0
        percent = 0
      progressBar = div {
        key: 'progressbar'
        style:
          display: 'block'
          width: COVER_WIDTH
          height: '10px'
          marginBottom: '3px'
          background: '#333333'
      }, [
        div {
          key: 'progressbarinner'
          style:
            width: "#{percent}%"
            height: '100%'
            background: '#669966'
        }
      ]
      linkContents.push progressBar

    linkContents.push cover

    link = a {
      key: 'link'
      href: href
      style:
        cursor: 'pointer'
    }, linkContents

    subtitle = div {
      key: 'subtitle'
      style:
        color: '#aaaaaa'
        fontSize: '0.7em'
    }, subtitleText

    if @props.progressEnabled
      menu = div {
        key: 'contextmenutext'
        style:
          cursor: 'pointer'
        onClick: =>
          @props.contextMenu(@props.info.dir)
      }, title
    else
      menu = div {
        key: 'contextmenutext'
      }, title

    entry = div {
      key: "BrowseEntry"
      style:
        display: 'inline-block'
        width: COVER_WIDTH
        textAlign: 'center'
        margin: '10px'
        verticalAlign: 'top'
    }, [
      link
      menu
      subtitle
    ]
    return entry

class BrowseTitle extends React.Component
  @defaultProps:
    title: null
    perc: 0
    color: '#aaaaaa'
    size: '1.2em'

  constructor: (props) ->
    super props

  render: ->
    if @props.title
      title = @props.title
    else if @props.perc == -1
      title = "Ignored:"
    else if @props.perc == 100
      title = "Completed:"
    else if @props.perc == 0
      title = "Unread:"
    else
      title = "Reading:"

    return div {
      style:
        color: @props.color
        fontSize: @props.size
        fontStyle: 'italic'
    }, title

class BrowseView extends React.Component
  constructor: (props) ->
    super props
    @state =
      contextMenuOpen: false
      contextMenuDir: ''
      sort: 'alphabetical'
      show: {}
    for k in ['reading', 'unread', 'completed', 'ignored']
      @state.show[k] = Settings.getBool("show.#{k}")
    if @props.progressEnabled
      @state.sort = 'interest'

  click: (info) ->

  contextMenu: (dir) ->
    @setState { contextMenuOpen: true, contextMenuDir: dir }

  updateShowFilter: (enabledList) ->
    show = {}
    for k of @state.show
      show[k] = false
    for v in enabledList
      show[v] = true
    for k, v of show
      Settings.set("show.#{k}", v)
    @setState { show: show }

  render: ->
    # ------------------------------------------------------------------------
    # Bail out if the directory doesn't make sense.

    if not @props.manifest.children.hasOwnProperty(@props.arg)
      return div {
        style:
          color: '#ffffff'
      }, "Invalid directory. Go home."

    # ------------------------------------------------------------------------
    # Prepare variables

    toolbarItems = []

    # ------------------------------------------------------------------------
    # Toolbar sorting choices

    sorts = [
      el MenuItem, {
        key: 'sort.alphabetical'
        value: 'alphabetical'
        primaryText: 'Alphabetical'
      }
      el MenuItem, {
        key: 'sort.recent'
        value: 'recent'
        primaryText: 'Recent'
      }
    ]

    if @props.progressEnabled
      sorts.unshift el MenuItem, {
        key: 'sort.interest'
        value: 'interest'
        primaryText: 'By Interest'
      }

    toolbarItems.push el ToolbarGroup, {
      key: 'toolbar.group.sort'
      float: 'right'
    }, [
      el DropDownMenu, {
        key: 'sortmenu'
        value: @state.sort
        onChange: (event, index, value) =>
          setTimeout =>
            @setState { sort: value }
          , 0
      }, sorts
    ]

    # ------------------------------------------------------------------------
    # If progress is on, add visibility filter

    if @props.progressEnabled
      enabledValues = Object.keys(@state.show).filter (e) => @state.show[e]
      # console.log "enabledValues", enabledValues
      toolbarItems.push el ToolbarGroup, {
        key: 'toolbar.group.filter'
        float: 'right'
      }, [
        el IconMenu, {
          key: 'filterbutton'
          iconButtonElement: el IconButton, {
              iconClassName: 'material-icons'
            }, 'filter_list'
          iconStyle: {}
          anchorOrigin: { horizontal: 'right', vertical: 'top' }
          targetOrigin: { horizontal: 'right', vertical: 'top' }
          value: enabledValues
          multiple: true
          onChange: (event, values) =>
            # Processing updateShowFilter() can take a reaaaaally long time on slow
            # devices, like an old Android tablet. If you try to do it synchronously,
            # it can cause the update to be lost and the change doesn't occur.
            setTimeout =>
              @updateShowFilter(values)
            , 0
        }, [
          el MenuItem, {
            key: 'menu.show'
            primaryText: "Show:"
            disabled: true
          }
          el MenuItem, {
            key: 'menu.reading'
            primaryText: "Reading"
            value: 'reading'
          }
          el MenuItem, {
            key: 'menu.unread'
            primaryText: "Unread"
            value: 'unread'
          }
          el MenuItem, {
            key: 'menu.completed'
            primaryText: "Completed"
            value: 'completed'
          }
          el MenuItem, {
            key: 'menu.ignored'
            primaryText: "Ignored"
            value: 'ignored'
          }
        ]
      ]

    # ------------------------------------------------------------------------
    # Create toolbar and spacing

    toolbar = el Toolbar, {
      key: 'toolbar'
      style:
        position: 'fixed'
        zIndex: 1
    }, toolbarItems

    spacing = div {
      key: 'spacing'
      style:
        height: '60px'
    }

    # ------------------------------------------------------------------------
    # Create base entries array

    entries = [toolbar, spacing]

    # ------------------------------------------------------------------------
    # Context Menu (right nav popout for progress stuff)

    if @props.progressEnabled
      contextMenuItems = [
        el MenuItem, {
          key: "contextmenu.dir"
          primaryText: @state.contextMenuDir
          disabled: true
        }
        el MenuItem, {
          key: "contextmenu.markread"
          primaryText: "Mark as Read"
          rightIcon: icon 'done'
          onTouchTap: (e) =>
            e.preventDefault()
            @setState { contextMenuOpen: false }
            setTimeout =>
              @props.dirAction(@state.contextMenuDir, 'mark')
            , 0
        }
        el MenuItem, {
          key: "contextmenu.markunread"
          primaryText: "Mark as Unread"
          rightIcon: icon 'done_all'
          onTouchTap: (e) =>
            e.preventDefault()
            @setState { contextMenuOpen: false }
            setTimeout =>
              @props.dirAction(@state.contextMenuDir, 'unmark')
            , 0
        }
        el MenuItem, {
          key: "contextmenu.ignore"
          primaryText: "Toggle Ignore"
          rightIcon: icon 'do_not_disturb'
          onTouchTap: (e) =>
            e.preventDefault()
            @setState { contextMenuOpen: false }
            setTimeout =>
              @props.dirAction(@state.contextMenuDir, 'ignore')
            , 0
        }
      ]

      entries.push el LeftNav, {
          key: 'contextmenu'
          docked: false
          openRight: true
          open: @state.contextMenuOpen
          disableSwipeToOpen: true
          onRequestChange: (open) => @setState { contextMenuOpen: open }
        }, contextMenuItems


    # ------------------------------------------------------------------------
    # Filter comics list based on current show filters, then sort what is left

    list = @props.manifest.children[@props.arg]
    unfilteredListSize = list.length
    if @props.progressEnabled
      if not @state.show.reading
        list = list.filter (e) -> (e.perc <= 0) or (e.perc >= 100)
      if not @state.show.unread
        list = list.filter (e) -> e.perc != 0
      if not @state.show.completed
        list = list.filter (e) -> e.perc != 100
      if not @state.show.ignored
        list = list.filter (e) -> e.perc != -1

    filteredListSize = list.length

    switch @state.sort
      when 'interest'
        list.sort (a, b) ->
          if a.perc == b.perc
            return -1 if a.dir < b.dir
            return  1 if a.dir > b.dir
            return 0
          return  1 if a.perc == 100
          return -1 if b.perc == 100
          return  1 if a.perc  <  b.perc
          return -1 if a.perc  >  b.perc
          return 0
      when 'alphabetical'
        list.sort (a, b) ->
          return -1 if a.dir < b.dir
          return  1 if a.dir > b.dir
          return 0
      when 'recent'
        list.sort (a, b) ->
          if a.timestamp == b.timestamp
            return -1 if a.dir < b.dir
            return  1 if a.dir > b.dir
            return 0
          return  1 if a.timestamp < b.timestamp
          return -1 if a.timestamp > b.timestamp
          return 0

    # ------------------------------------------------------------------------
    # Create view entries

    lastPerc = null
    sawOneEntry = false
    for entry in list
      if @props.progressEnabled and (@state.sort == 'interest')
        if lastPerc == null
          entries.push el BrowseTitle, { key: "browsetitle.perc#{entry.perc}", perc: entry.perc }
        else
          addDivider = false
          if ((lastPerc != -1) and (entry.perc == -1))
            addDivider = true
          if ((lastPerc != 100) and (entry.perc == 100))
            addDivider = true
          if ((lastPerc != 0) and (entry.perc == 0))
            addDivider = true
          if addDivider
            entries.push hr {
              key: "hr.perc#{entry.perc}"
              size: 1
              style:
                borderColor: '#777777'
            }
            entries.push el BrowseTitle, { key: "browsetitle.perc#{entry.perc}", perc: entry.perc }
        lastPerc = entry.perc

      sawOneEntry = true
      entryElement = el BrowseEntry, {
        key: entry.dir
        info: entry
        contextMenu: @contextMenu.bind(this)
        redirect: @props.redirect
        progressEnabled: @props.progressEnabled
      }
      entries.push entryElement

    if sawOneEntry
      if filteredListSize != unfilteredListSize
        entries.push hr {
          key: "hr.filtered"
          size: 1
          style:
            borderColor: '#777777'
        }
        entries.push el BrowseTitle, { key: "text.filtercount", title: "Filtered #{unfilteredListSize - filteredListSize} item(s).", size: '0.7em' }
    else
      entries.push el BrowseTitle, { key: "text.none", title: "Showing none of the #{unfilteredListSize} item(s) here. Please adjust your filter." }

    # ------------------------------------------------------------------------
    # Create view

    view = div {
      key: 'browseview'
      style:
        width: '100%'
        height: '100%'
        backgroundColor: '#111111'
        textAlign: 'center'
    }, entries

    return view

module.exports = BrowseView
