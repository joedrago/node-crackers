# React
React = require 'react'
DOM = require 'react-dom'

# Material UI components
DropDownMenu = require 'material-ui/lib/DropDownMenu'
FlatButton = require 'material-ui/lib/flat-button'
IconButton = require 'material-ui/lib/icon-button'
IconMenu = require 'material-ui/lib/menus/icon-menu'
MenuItem = require 'material-ui/lib/menus/menu-item'
Toolbar = require 'material-ui/lib/toolbar/toolbar'
ToolbarGroup = require 'material-ui/lib/toolbar/toolbar-group'
ToolbarSeparator = require 'material-ui/lib/toolbar/toolbar-separator'
ToolbarTitle = require 'material-ui/lib/toolbar/toolbar-title'

# Local requires
{a, div, el, img, hr, span} = require '../tags'

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
        href = "#comic/#{@props.info.dir}"
        subtitleText = "(#{@props.info.pages} pages)"
      when 'index'
        href = "#browse/#{@props.info.dir}"
        subtitleText = "(#{@props.info.count} comics, Newest: #{@props.info.recent})"

    title = span {
      key: 'title'
      style:
        fontWeight: 900
        color: '#ffffff'
    }, @props.info.dir.replace(/\//g, " | ")

    linkContents = []

    hasProgress = @props.info.hasOwnProperty('perc')
    if hasProgress
      percent = @props.info.perc
      if percent < 0
        percent = 0
      progressBar = div {
        style:
          display: 'block'
          width: COVER_WIDTH
          height: '10px'
          marginBottom: '3px'
          background: '#333333'
      }, [
        div {
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

    menuItems = [
      el MenuItem, {
        primaryText: "Open"
        onTouchTap: => @props.redirect(href)
      }
    ]

    if hasProgress
      menuItems.push el MenuItem, {
        primaryText: "Mark as Read"
        onTouchTap: => @props.dirAction(@props.info.dir, 'mark')
      }
      menuItems.push el MenuItem, {
        primaryText: "Mark as Unread"
        onTouchTap: => @props.dirAction(@props.info.dir, 'unmark')
      }
      menuItems.push el MenuItem, {
        primaryText: "Toggle Ignore"
        onTouchTap: => @props.dirAction(@props.info.dir, 'ignore')
      }

    menu = el IconMenu, {
      iconButtonElement: el FlatButton, {
        label: title
        style:
          lineHeight: '16px'
          textTransform: 'none'
      }
      anchorOrigin: { horizontal: 'left', vertical: 'top' }
      targetOrigin: { horizontal: 'left', vertical: 'top' }
    }, menuItems

    entry = div {
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

class BrowseView extends React.Component
  constructor: (props) ->
    super props
    @state =
      sort: 'recent'
      showIgnored: false
      showCompleted: false
    if @props.progressEnabled
      @state.sort = 'interest'

  click: (info) ->
    # if @props.onChangeDir
    #   @props.onChangeDir(info.dir)

  render: ->
    if not @props.manifest.children.hasOwnProperty(@props.arg)
      return div {
        style:
          color: '#ffffff'
      }, "Invalid directory. Go home."

    sorts = [
      el MenuItem, {
        value: 'alphabetical'
        primaryText: 'Alphabetical'
      }
      el MenuItem, {
        value: 'recent'
        primaryText: 'Recent'
      }
    ]

    if @props.progressEnabled
      sorts.unshift el MenuItem, {
        value: 'interest'
        primaryText: 'By Interest'
      }

    menuItems = []
    if @props.progressEnabled
      label = "Show Ignored"
      if @state.showIgnored
        label = "Hide Ignored"
      menuItems.push el MenuItem, {
        primaryText: label
        onTouchTap: => @setState { showIgnored: !@state.showIgnored }
      }
      label = "Show Completed"
      if @state.showCompleted
        label = "Hide Completed"
      menuItems.push el MenuItem, {
        primaryText: label
        onTouchTap: => @setState { showCompleted: !@state.showCompleted }
      }

    toolbar = el Toolbar, {
      style:
        position: 'fixed'
    }, [
      el ToolbarGroup, {
        float: 'right'
      }, [
        el IconMenu, {
          iconButtonElement: el IconButton, {
              iconClassName: 'material-icons'
            }, 'expand_more'
          anchorOrigin: { horizontal: 'left', vertical: 'top' }
          targetOrigin: { horizontal: 'left', vertical: 'top' }
        }, menuItems

        el ToolbarSeparator
        el DropDownMenu, {
          value: @state.sort
          onChange: (event, index, value) => @setState { sort: value }
        }, sorts
      ]
    ]

    spacing = div {
      style:
        height: '60px'
    }

    list = @props.manifest.children[@props.arg]
    console.log list
    if @props.progressEnabled
      if not @state.showIgnored
        list = list.filter (e) -> e.perc != -1
      if not @state.showCompleted
        list = list.filter (e) -> e.perc != 100

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
          return  1 if a.dir < b.dir
          return -1 if a.dir > b.dir
          return 0

    entries = [toolbar, spacing]
    lastPerc = null
    for entry in list
      if @props.progressEnabled and (@state.sort == 'interest')
        if lastPerc != null
          addDivider = false
          if ((lastPerc != -1) and (entry.perc == -1))
            addDivider = true
          if ((lastPerc != 100) and (entry.perc == 100))
            addDivider = true
          if ((lastPerc != 0) and (entry.perc == 0))
            addDivider = true
          if addDivider
            entries.push hr {
              size: 1
              style:
                borderColor: '#777777'
            }
        lastPerc = entry.perc

      entryElement = React.createElement BrowseEntry, {
        key: entry.dir
        info: entry
        dirAction: @props.dirAction
        redirect: @props.redirect
      }
      entries.push entryElement

    view = div {
      style:
        width: '100%'
        height: '100%'
        backgroundColor: '#111111'
        textAlign: 'center'
    }, entries

    return view

module.exports = BrowseView
