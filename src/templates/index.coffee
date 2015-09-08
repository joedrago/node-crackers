if isMobile.any
  prevUrl = "#inject{prev}"
  if prevUrl
    $("body").append "<a class=\"box prevbox\" href=\""+prevUrl+"\">&nbsp;</a>"
