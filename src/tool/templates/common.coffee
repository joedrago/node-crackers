$(->
  qs = window.location.search
  if qs
    $('a[href]').each ->
      elem = $(this)
      href = elem.attr('href')
      elem.attr('href', href + qs)
)

window.getOpt = (name) ->
  match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search)
  return "" if not match
  return String(decodeURIComponent(match[1].replace(/\+/g, ' ')))

window.getOptBool = (name, defaultValue = false) ->
  switch getOpt(name)
    when ""
      defaultValue
    when "1", "true", "on", "yes"
      true
    else
      false

window.getOptInt = (name, defaultValue = 0) ->
  v = getOpt(name)
  switch v
    when ""
      defaultValue
    else
      parseInt(v)

