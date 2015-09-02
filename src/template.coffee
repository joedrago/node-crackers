fs = require 'fs'

module.exports = (name, replacements) ->
  templateFilename = __dirname + "/../templates/#{name}.html"
  if not fs.existsSync(templateFilename)
    return ""
  rawTemplate = fs.readFileSync(templateFilename)
  templateLines = String(rawTemplate).split(/(?:\n|\r\n|\r)/g)

  outputText = ""
  for line in templateLines
    line = line.replace /#inject\{([^\}]+)\}/g, (match, key) ->
      return replacements[key] ? ""
    outputText += line
    outputText += "\n"

  return outputText
