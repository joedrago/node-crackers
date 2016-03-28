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
    if not @props.manifest.exists[dir]
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

    return el ComicRenderer, {
      metadata: @state.metadata
      width: @props.width
      height: @props.height
    }

module.exports = ComicView
