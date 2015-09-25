// Generated by CoffeeScript 1.9.3
(function() {
  var altZoom, endZoom, fadeIn, fadeOut, fotorama, helpShowing, nextUrl, prevUrl, spaceHeld, spaceMovedZoom, touchTimestamp, updateZoom, updateZoomPos, zoomScale, zoomScaleIndex, zoomScales, zoomX, zoomY;

  touchTimestamp = null;

  zoomScales = [1.5, 2, 2.5, 3];

  zoomScaleIndex = 0;

  zoomScale = zoomScales[zoomScaleIndex];

  zoomX = 0;

  zoomY = 0;

  altZoom = getOptBool('altzoom');

  spaceHeld = false;

  spaceMovedZoom = false;

  helpShowing = false;

  prevUrl = "#inject{prev}";

  nextUrl = "#inject{next}";

  Number.prototype.clamp = function(min, max) {
    return Math.min(Math.max(this, min), max);
  };

  updateZoomPos = function(t) {
    zoomX = ((t.clientX - t.target.offsetLeft) / t.target.clientWidth).clamp(0, 1);
    zoomY = ((t.clientY - t.target.offsetTop) / t.target.clientHeight).clamp(0, 1);
    if (altZoom) {
      zoomX = Math.round(zoomX);
      return zoomY = Math.round(zoomY);
    }
  };

  updateZoom = function() {
    var diffh, diffw, h, ih, iw, offX, offY, tf, w;
    w = 0;
    h = 0;
    $(".fotorama__stage__frame.fotorama__active").each(function() {
      w = this.clientWidth;
      return h = this.clientHeight;
    });
    iw = 0;
    ih = 0;
    $(".fotorama__stage__frame.fotorama__active img").each(function() {
      iw = this.width;
      return ih = this.height;
    });
    if ((w > 0) && (h > 0)) {
      offX = (zoomScale - 1) * -w * zoomX;
      offY = (zoomScale - 1) * -h * zoomY;
      if ((iw > 0) && (ih > 0)) {
        diffw = w - iw;
        diffh = h - ih;
        offX += (zoomX - 0.5) * (diffw * zoomScale);
        offY += (zoomY - 0.5) * (diffh * zoomScale);
      }
      tf = "translate(" + offX + "px, " + offY + "px) scale(" + zoomScale + ")";
      return $(".fotorama__stage__frame.fotorama__active").css({
        "transform-origin": "0px 0px",
        "transform": tf
      });
    }
  };

  endZoom = function() {
    return $(".fotorama__stage__frame.fotorama__active").css({
      "transform-origin": "0px 0px",
      "transform": "translate(0px, 0px) scale(1)"
    });
  };

  fadeIn = function() {
    if (altZoom) {
      console.log("fade in");
      return $('#zoombox').finish().fadeTo(100, 0.5);
    }
  };

  fadeOut = function() {
    if (altZoom) {
      console.log("fade out");
      return $('#zoombox').delay(250).fadeTo(250, 0);
    }
  };

  window.touchMove = function(event) {
    event.preventDefault();
    updateZoomPos(event.changedTouches[0]);
    return updateZoom();
  };

  window.touchStart = function(event) {
    event.preventDefault();
    touchTimestamp = new Date().getTime();
    updateZoomPos(event.changedTouches[0]);
    updateZoom();
    return fadeIn();
  };

  window.touchEnd = function(event) {
    var diff, endTouchTimestamp;
    event.preventDefault();
    endTouchTimestamp = new Date().getTime();
    diff = endTouchTimestamp - touchTimestamp;
    if (diff < 100) {
      endZoom();
    }
    return fadeOut();
  };

  window.nextScale = function(event) {
    event.preventDefault();
    zoomScaleIndex = (zoomScaleIndex + 1) % zoomScales.length;
    zoomScale = zoomScales[zoomScaleIndex];
    return updateZoom();
  };

  $(document).keydown(function(event) {
    var fotorama;
    console.log("keydown", event.keyCode);
    if (helpShowing) {
      helpShowing = false;
      $('#help').fadeOut();
    }
    switch (event.keyCode) {
      case 49:
      case 50:
      case 51:
      case 52:
        zoomScaleIndex = event.keyCode - 49;
        zoomScale = zoomScales[zoomScaleIndex];
        updateZoom();
        break;
      case 192:
        endZoom();
        break;
      case 81:
        zoomX = 0;
        zoomY = 0;
        updateZoom();
        break;
      case 87:
        zoomX = 1;
        zoomY = 0;
        updateZoom();
        break;
      case 65:
        zoomX = 0;
        zoomY = 1;
        updateZoom();
        break;
      case 83:
        zoomX = 1;
        zoomY = 1;
        updateZoom();
        break;
      case 90:
        fotorama = $('.fotorama').data('fotorama');
        fotorama.show('<');
        break;
      case 88:
        fotorama = $('.fotorama').data('fotorama');
        fotorama.show('>');
        break;
      case 78:
        if (nextUrl) {
          window.location = nextUrl;
        }
        break;
      case 80:
        if (prevUrl) {
          window.location = prevUrl;
        }
        break;
      case 66:
      case 73:
        window.location = '../';
        break;
      case 72:
      case 191:
        if (!helpShowing) {
          helpShowing = true;
          $('#help').fadeIn();
        }
        break;
      case 32:
        spaceHeld = true;
    }
  });

  $(document).keyup(function(event) {
    switch (event.keyCode) {
      case 32:
        spaceHeld = false;
        if (spaceMovedZoom) {
          spaceMovedZoom = false;
        } else {
          endZoom();
        }
    }
  });

  $(document).mousemove(function(event) {
    if (spaceHeld) {
      updateZoomPos(event);
      updateZoom();
      return spaceMovedZoom = true;
    }
  });

  fotorama = $('.fotorama');

  fotorama.on('fotorama:show fotorama:showend', function(e, fotorama, extra) {
    return endZoom();
  });

  fotorama.fotorama();

  if (isMobile.any) {
    if (altZoom) {
      $("body").append("<div id=\"zoombox\" class=\"altzoombox\" ontouchmove=\"touchMove(event)\" ontouchstart=\"touchStart(event)\" ontouchend=\"touchEnd(event)\"></div>");
      $("#zoombox").append("<div class=\"altzoomcross\"</div>");
    } else {
      $("body").append("<div id=\"zoombox\" class=\"box zoombox\" ontouchmove=\"touchMove(event)\" ontouchstart=\"touchStart(event)\" ontouchend=\"touchEnd(event)\"></div>");
      if (isMobile.tablet) {
        $('#zoombox').css("width", "10vw");
        $('#zoombox').css("height", "10vh");
      }
    }
    fadeOut();
    $("body").append("<div class=\"box scalebox\" ontouchstart=\"nextScale(event)\"></div>");
    if (prevUrl) {
      $("body").append("<a class=\"box prevbox\" href=\"" + prevUrl + "\"></a>");
    }
    if (nextUrl) {
      $("body").append("<a class=\"box nextbox\" href=\"" + nextUrl + "\"></a>");
    }
  }

}).call(this);
