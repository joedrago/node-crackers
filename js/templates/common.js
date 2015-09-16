// Generated by CoffeeScript 1.9.3
(function() {
  $(function() {
    var qs;
    qs = window.location.search;
    if (qs) {
      return $('a[href]').each(function() {
        var elem, href;
        elem = $(this);
        href = elem.attr('href');
        return elem.attr('href', href + qs);
      });
    }
  });

  window.getOpt = function(name) {
    var match;
    match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
    if (!match) {
      return "";
    }
    return String(decodeURIComponent(match[1].replace(/\+/g, ' ')));
  };

  window.getOptBool = function(name) {
    switch (getOpt(name)) {
      case "1":
      case "true":
      case "on":
      case "yes":
        return true;
      default:
        return false;
    }
  };

}).call(this);