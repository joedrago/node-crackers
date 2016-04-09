# This is just a bunch of helper functions / factories for making certain html elements (tags).
# Dumb name; very convenient shorthand.

React = require 'react'
FontIcon = require 'material-ui/lib/font-icon'

tags = ['a', 'div', 'hr', 'img', 'span']

module.exports = {}
for elementName in tags
  module.exports[elementName] = React.createFactory(elementName)

module.exports.el = React.createElement

module.exports.icon = (which) ->
  return React.createElement(FontIcon, { className: 'material-icons' }, which)
