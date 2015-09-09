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

window.getOptBool = (name) ->
  switch getOpt(name)
    when "1", "true", "on", "yes"
      true
    else
      false

