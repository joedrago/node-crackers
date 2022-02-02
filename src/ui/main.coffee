React = require 'react'
DOM = require 'react-dom'
App = require './App'
progressEnabled = "#inject{progress}" == "true"
endpoint = "#inject{endpoint}"
auth = "#inject{auth}"
DOM.render(React.createElement(App, { progressEnabled: progressEnabled, endpoint: endpoint, auth: auth }), document.getElementById('appcontainer'))

'globals: progressEnabled endpoint auth'
