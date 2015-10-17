if isMobile.any
  prevUrl = "#inject{prev}"
  if prevUrl
    $("body").append "<a class=\"box indexbox\" href=\""+prevUrl+"\"></a>"

recentCover = false
currentSort = -1
sorts = [
  {
    name: 'Alphabetical'
    func: (a, b) ->
      ca = $(a).data('title')
      cb = $(b).data('title')
      return -1 if ca < cb
      return  1 if ca > cb
      return 0
  }

  {
    name: 'Recent'
    func: (a, b) ->
      ca = parseInt($(a).data('timestamp'))
      cb = parseInt($(b).data('timestamp'))
      return  1 if ca < cb
      return -1 if ca > cb
      return 0
  }
]
window.sorts = sorts

window.sort = (how) ->
  currentSort = how
  $('.sortowned').remove()
  if(sorts[currentSort].pre)
    sorts[currentSort].pre()
  divs = $('.sorted')
  divs.sort(sorts[currentSort].func)
  if(sorts[currentSort].post)
    sorts[currentSort].post()
  $('#entries').append(divs)
  $('#sortorder').text(sorts[currentSort].name)
  return

window.nextsort = (event) ->
  event.preventDefault() if event?
  window.sort((currentSort + 1) % sorts.length)
  return

window.resort = (event) ->
  event.preventDefault() if event?
  window.sort(currentSort)
  return

window.toggleRecentCover = (event) ->
  event.preventDefault() if event?
  attrName = 'data-cover'
  name = 'First Cover'
  recentCover = !recentCover
  if recentCover
    attrName = 'data-recentcover'
    name = 'Newest Cover'
  $('.sorted img').each ->
    cover = $(this).attr(attrName)
    $(this).attr('src', cover)
  $('#togglerecent').text(name)

$(->
  nextsort()
)
