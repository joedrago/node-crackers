$(->
  loadLocal = (path, cb) ->
    console.log "loading JS: #{path}"
    element = document.createElement("script")
    element.src = path
    document.body.appendChild element
    element.onload = element.onreadystatechange = ->
      console.log "JS loaded: #{path}"
      cb() if cb

  generator = "#inject{generator}"
  root = "#inject{root}"
  if generator and root
    loadLocal "#{root}/local.js", ->
      loadLocal "#{root}/local.#{generator}.js", ->
        if window.onLocalLoaded
          window.onLocalLoaded()
)
