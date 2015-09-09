// Generated by CoffeeScript 1.9.3
(function() {
  var altZoom, endZoom, fotorama, nextUrl, prevUrl, touchTimestamp, updateZoom, updateZoomPos, zoomScale, zoomScaleIndex, zoomScales, zoomX, zoomY;

  touchTimestamp = null;

  zoomScales = [1.5, 2, 2.5, 3];

  zoomScaleIndex = 0;

  zoomScale = zoomScales[zoomScaleIndex];

  zoomX = 0;

  zoomY = 0;

  altZoom = getOptBool('altzoom');

  Number.prototype.clamp = function(min, max) {
    return Math.min(Math.max(this, min), max);
  };

  updateZoomPos = function(event) {
    var t;
    t = event.changedTouches[0];
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
    console.log(w + " " + h + " " + iw + " " + ih);
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

  window.touchMove = function(event) {
    event.preventDefault();
    updateZoomPos(event);
    return updateZoom();
  };

  window.touchStart = function(event) {
    event.preventDefault();
    touchTimestamp = new Date().getTime();
    updateZoomPos(event);
    return updateZoom();
  };

  window.touchEnd = function(event) {
    var diff, endTouchTimestamp;
    event.preventDefault();
    endTouchTimestamp = new Date().getTime();
    diff = endTouchTimestamp - touchTimestamp;
    if (diff < 100) {
      return endZoom();
    }
  };

  window.nextScale = function(event) {
    event.preventDefault();
    zoomScaleIndex = (zoomScaleIndex + 1) % zoomScales.length;
    zoomScale = zoomScales[zoomScaleIndex];
    return updateZoom();
  };

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
      $("body").append("<div id=\"zoombox\" class=\"box zoombox\" ontouchmove=\"touchMove(event)\" ontouchstart=\"touchStart(event)\" ontouchend=\"touchEnd(event)\">&nbsp</div>");
      if (isMobile.tablet) {
        $('#zoombox').css("width", "10vw");
        $('#zoombox').css("height", "10vh");
      }
    }
    $("body").append("<div class=\"box scalebox\" ontouchstart=\"nextScale(event)\">&nbsp</div>");
    prevUrl = "#inject{prev}";
    nextUrl = "#inject{next}";
    if (prevUrl) {
      $("body").append("<a class=\"box prevbox\" href=\"" + prevUrl + "\">&nbsp</a>");
    }
    if (nextUrl) {
      $("body").append("<a class=\"box nextbox\" href=\"" + nextUrl + "\">&nbsp</a>");
    }
  }

}).call(this);
