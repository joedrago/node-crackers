React = require 'react'
DOM = require 'react-dom'
App = require './App'
progressEnabled = "#inject{progress}" == "true"
endpoint = "#inject{endpoint}"
DOM.render(React.createElement(App, { progressEnabled: progressEnabled, endpoint: endpoint }), document.getElementById('appcontainer'))
