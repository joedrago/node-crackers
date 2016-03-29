React = require 'react'

tags = ['a', 'div', 'hr', 'img', 'span']

module.exports = {}
for elementName in tags
  module.exports[elementName] = React.createFactory(elementName)

module.exports.el = React.createElement
