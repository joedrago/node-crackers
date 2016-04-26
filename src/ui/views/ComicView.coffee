# React
React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'

# Local requires
loadMetadata = require '../MetadataCache'
tags = require '../tags'
{el} = require '../tags'

ComicRenderer = require '../ComicRenderer'

class ComicView extends React.Component
  constructor: (props) ->
    super props
    @state =
      dir: null
      metadata: null
      metadataUrl: null

    @changeDir(props.arg, true)

  componentWillReceiveProps: (nextProps) ->
    # console.log "componentWillReceiveProps", nextProps
    @changeDir(nextProps.arg)

  changeDir: (dir, fromConstructor = false) ->
    # console.log "changeDir(#{dir}), current state #{@state.dir}"
    comicExists = false
    if @props.manifest.hasOwnProperty('exists') and @props.manifest.exists[dir]
      comicExists = true
    if @props.manifest.hasOwnProperty('page') and @props.manifest.page.hasOwnProperty(dir)
      comicExists = true
    if not comicExists
      dir = null
    if @state.dir != dir
      if fromConstructor
        @state.dir = dir
        @state.metadata = null
      else
        @setState {
          dir: dir
          metadata: null
        }
    if comicExists
      @loadMetadata(dir)

  loadMetadata: (dir) ->
    loadMetadata dir, (metadata) =>
      dir = @state.dir
      if metadata == null
        dir = null
      @setState {
        dir: dir
        metadata: metadata
      }

  render: ->
    if @state.dir == null
      return tags.div {
        style:
          color: '#ffffff'
      }, "Invalid comic. Go Home."

    if @state.metadata == null
      return el Loader, {
        color: '#222222'
      }

    page = null
    if @props.manifest.hasOwnProperty('page')
      page = @props.manifest.page[@state.dir]
    return el ComicRenderer, {
      metadata: @state.metadata
      width: @props.width
      height: @props.height
      dir: @state.dir
      page: page
      redirect: @props.redirect
      onViewPage: @props.onViewPage
    }

module.exports = ComicView
