React = require 'react'
DOM = require 'react-dom'
IndexView = require './IndexView'
BurgerMenu = require('react-burger-menu').stack
{a, div} = require './tags'

class App extends React.Component
  @defaultProps:
    start: 0

  constructor: (props) ->
    super props
    @state =
      manifest: null

    @loadManifest()

  loadManifest: ->
    $.getJSON 'manifest.crackers', null, (manifest, status) =>
      @setState { manifest: manifest }

  render: ->
    div null, [
      React.createElement(BurgerMenu, {
        key: 'burger'
        styles:
          bmBurgerButton:
            position: 'fixed'
            width: '36px'
            height: '30px'
            left: '4px'
            top: '4px'
          bmBurgerBars:
            background: '#373a47'
          bmCrossButton:
            height: '24px'
            width: '24px'
          bmCross:
            background: '#bdc3c7'
          bmMenu:
            background: '#373a47'
            padding: '2.5em 1.5em 0'
            fontSize: '1.15em'
            fontStyle: 'italic'
          bmMorphShape:
            fill: '#373a47'
          bmItem:
            cursor: 'pointer'
          bmItemList:
            color: '#b8b7ad'
            padding: '0.8em'
          bmOverlay:
            background: 'rgba(0, 0, 0, 0.3)'
        }, [
          a {
            key: 'home'
            onClick: => console.log "going home!"
          }, "Home"
      ])
      React.createElement(IndexView, { key: 'indexview', manifest: @state.manifest })
    ]

module.exports = App
