React = require 'react'
DOM = require 'react-dom'
Loader = require 'react-loader'
{el, div, img} = require '../tags'

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
    console.log "componentWillReceiveProps", nextProps
    @changeDir(nextProps.arg)

  changeDir: (dir, fromConstructor = false) ->
    console.log "changeDir(#{dir}), current state #{@state.dir}"
    metadataUrl = "#{dir}/meta.crackers"
    comicExists = false
    if @props.manifest.hasOwnProperty('exists') and @props.manifest.exists[dir]
      comicExists = true
    if @props.manifest.hasOwnProperty('page') and @props.manifest.page.hasOwnProperty(dir)
      comicExists = true
    if not comicExists
      dir = null
      metadataUrl = null
    if @state.dir != dir
      if fromConstructor
        @state.dir = dir
        @state.metadata = null
        @state.metadataUrl = metadataUrl
      else
        @setState {
          dir: dir
          metadata: null
          metadataUrl: metadataUrl
        }
    if metadataUrl
      @loadMetadata(metadataUrl)

  loadMetadata: (url) ->
    # metadata = null
    # metadata = @metadataCache.get(dir)
    # if metadata
    #   console.log "using cached metadata: #{dir}"
    #   @setState {
    #     metadata: metadata
    #   }
    # else
    $.getJSON(url)
    .success (metadata) =>
      # @comicMetadataCache.put metadataDir, metadata
      @setState {
        metadata: metadata
      }
    .error ->
      console.log "lel error!"
      @setState {
        dir: null
      }

  render: ->
    if @state.dir == null
      return div {
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
      onViewPage: @props.onViewPage
    }

module.exports = ComicView
