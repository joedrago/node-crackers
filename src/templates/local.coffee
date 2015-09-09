$(->
  loadLocal = (path) ->
    # console.log "loading JS: #{path}"
    element = document.createElement("script")
    element.src = path
    document.body.appendChild element

  generator = "#inject{generator}"
  root = "#inject{root}"
  if generator and root
    loadLocal("#{root}/local.js")
    loadLocal("#{root}/local.#{generator}.js")
)
