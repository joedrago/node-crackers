if isMobile.any
  prevUrl = "#inject{prev}"
  if prevUrl
    $("body").append "<a class=\"box prevbox\" href=\""+prevUrl+"\"></a>"

currentSort = -1
sorts = [
  {
    name: 'Alphabetical'
    func: (a, b) ->
      ca = $(a).attr('data-title')
      cb = $(b).attr('data-title')
      return -1 if ca < cb
      return  1 if ca > cb
      return 0
  }

  {
    name: 'Recent'
    func: (a, b) ->
      ca = parseInt($(a).attr('data-timestamp'))
      cb = parseInt($(b).attr('data-timestamp'))
      return  1 if ca < cb
      return -1 if ca > cb
      return 0
  }
]

window.nextsort = (event) ->
  event.preventDefault() if event?
  currentSort = (currentSort + 1) % sorts.length
  divs = $('.sorted')
  divs.sort(sorts[currentSort].func)
  $('#entries').append(divs)
  $('#sortorder').text(sorts[currentSort].name)
  return

$(->
  nextsort()
)
