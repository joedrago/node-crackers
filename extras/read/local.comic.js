function updatePage(page)
{
  console.log("updatePage("+page+")");
  window.readRequest({
    page: page,
    skip: true
  });
}

var pageTimer = null;
window.onPage = function(page) {
  if(pageTimer != null) {
    clearTimeout(pageTimer);
  }
  pageTimer = setTimeout(function() { updatePage(page) }, 1000);
}

window.readRequest({ pos: true, skip: true }, function(data) {
    fotorama = $('.fotorama').data('fotorama');
    if(data.pos) {
        fotorama.show(data.pos - 1);
    }
});
