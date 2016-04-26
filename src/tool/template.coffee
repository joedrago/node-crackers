fs = require 'fs'
cfs = require './cfs'
path = require 'path'
constants = require './constants'

# Cache all templates in the templates dir (extension is only for editing them)
templates = {}
defaultReplacements = {}

do ->
  for k,v of constants
    k = k.replace(/_/, "").toLowerCase()
    defaultReplacements[k] = String(v)

  loadTemplateDir = (templateDir) ->
    templateFiles = cfs.listDir(templateDir)
    for templateFile in templateFiles
      filename = cfs.join(templateDir, templateFile)
      if not fs.existsSync(filename)
        continue
      rawTemplate = fs.readFileSync(filename)
      templateLines = String(rawTemplate).split(/(?:\n|\r\n|\r)/g)
      parsed = path.parse(filename)

      name = parsed.base.replace(".", "_")
      templates[name] = templateLines

  loadTemplateDir(__dirname + "/../templates")
  loadTemplateDir(__dirname + "/../build/templates")

interpTemplate = (name, replacements) ->
  if not templates[name]
    return ""

  defaultReplacement = (key) ->
    return defaultReplacements[key] ? ""

  templateLines = templates[name]
  outputText = ""
  for line in templateLines.slice(0)
    line = line.replace /#inject\{([^\}]+)\}/g, (match, key) ->
      return replacements[key] ? defaultReplacement(key)
    line = line.replace /#include\{([^\}]+)\}/g, (match, key) ->
      return interpTemplate(key, replacements)
    outputText += line
    outputText += "\n"

  return outputText

module.exports = interpTemplate

'globals: defaultReplacements templates'
