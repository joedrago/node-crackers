React = require 'react'

tags = ['div', 'img']

module.exports = {}
for elementName in tags
  module.exports[elementName] = React.createFactory(elementName)
