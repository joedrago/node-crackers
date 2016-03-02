React = require 'react'

E = {}
for elementName in ['div', 'h1']
  E[elementName] = React.createFactory(elementName)

module.exports = E
