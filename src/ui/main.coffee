React = require 'react'
DOM = require 'react-dom'
App = require './App'

DOM.render(React.createElement(App), document.getElementById('appcontainer'))
