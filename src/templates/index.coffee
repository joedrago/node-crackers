if isMobile.any
  prevUrl = "#inject{prev}"
  if prevUrl
    $("body").append "<a class=\"prevbox\" href=\""+prevUrl+"\">&nbsp;</a>"
