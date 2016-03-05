React = require 'react'

tags = ['a', 'div', 'img', 'span']

module.exports = {}
for elementName in tags
  module.exports[elementName] = React.createFactory(elementName)