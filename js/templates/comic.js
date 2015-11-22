// Generated by CoffeeScript 1.9.3
(function() {
  var Auto, altZoom, autoNext, autoPrev, autoState, autoStateOnShowEnd, endZoom, fadeIn, fadeOut, fotorama, helpShowing, loadNextImage, loadedImages, nextLoadIndex, nextUrl, preloadImages, preloadImagesDefault, prevUrl, spaceHeld, spaceMovedZoom, touchTimestamp, updateZoom, updateZoomPos, zoomScale, zoomScaleIndex, zoomScales, zoomToCorner, zoomX, zoomY;

  touchTimestamp = null;

  zoomScales = [1.5, 2, 2.5, 3];

  zoomScaleIndex = 0;

  zoomScale = zoomScales[zoomScaleIndex];

  zoomX = 0;

  zoomY = 0;

  altZoom = getOptBool('altzoom');

  preloadImagesDefault = true;

  preloadImages = getOptBool('preload', preloadImagesDefault);

  spaceHeld = false;

  spaceMovedZoom = false;

  helpShowing = false;

  prevUrl = "#inject{prev}";

  nextUrl = "#inject{next}";

  
var comicImages = [
#inject{jslist}
null]
comicImages.pop()
;

  Auto = {
    None: 0,
    TopLeft: 1,
    BottomRight: 2
  };

  autoState = Auto.None;

  autoStateOnShowEnd = Auto.None;

  Number.prototype.clamp = function(min, max) {
    return Math.min(Math.max(this, min), max);
  };

  updateZoomPos = function(t) {
    var zX, zY;
    zoomX = ((t.clientX - t.target.offsetLeft) / t.target.clientWidth).clamp(0, 1);
    zoomY = ((t.clientY - t.target.offsetTop) / t.target.clientHeight).clamp(0, 1);
    if (altZoom) {
      zX = Math.min(1, Math.floor(zoomX * 3) / 2);
      zY = Math.min(1, Math.floor(zoomY * 3) / 2);
      if ((zX === 0.5) && (zY === 0.5)) {
        zoomX = Math.max(0, zoomX - (1 / 4)) * 2;
        return zoomY = Math.max(0, zoomY - (1 / 4)) * 2;
      } else {
        zoomX = zX;
        return zoomY = zY;
      }
    }
  };

  updateZoom = function() {
    var diffh, diffw, h, ih, iw, offX, offY, scaledH, scaledW, tf, transformOriginX, transformOriginY, w;
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
    transformOriginX = "0px";
    transformOriginY = "0px";
    if ((w > 0) && (h > 0)) {
      offX = (zoomScale - 1) * -w * zoomX;
      offY = (zoomScale - 1) * -h * zoomY;
      if ((iw > 0) && (ih > 0)) {
        diffw = w - iw;
        diffh = h - ih;
        offX += (zoomX - 0.5) * (diffw * zoomScale);
        offY += (zoomY - 0.5) * (diffh * zoomScale);
      }
      scaledW = zoomScale * iw;
      scaledH = zoomScale * ih;
      if (scaledW < w) {
        transformOriginX = "50%";
        offX = 0;
      }
      if (scaledH < h) {
        transformOriginY = "50%";
        offY = 0;
      }
      tf = "translate(" + offX + "px, " + offY + "px) scale(" + zoomScale + ")";
      return $(".fotorama__stage__frame.fotorama__active").css({
        "transform-origin": transformOriginX + " " + transformOriginY,
        "transform": tf
      });
    }
  };

  endZoom = function() {
    $(".fotorama__stage__frame.fotorama__active").css({
      "transform-origin": "0px 0px",
      "transform": "translate(0px, 0px) scale(1)"
    });
    return autoState = Auto.None;
  };

  fadeIn = function() {
    if (altZoom) {
      return $('#zoombox').finish().fadeTo(100, 0.5);
    }
  };

  fadeOut = function() {
    if (altZoom) {
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

  zoomToCorner = function(x, y) {
    if ((x === 0) && (x === 0)) {
      autoState = Auto.TopLeft;
    } else if ((x === 1) && (y === 1)) {
      autoState = Auto.BottomRight;
    } else {
      autoState = Auto.None;
    }
    zoomX = x;
    zoomY = y;
    return updateZoom();
  };

  autoPrev = function() {
    var fotorama;
    switch (autoState) {
      case Auto.None:
        autoStateOnShowEnd = Auto.BottomRight;
        fotorama = $('.fotorama').data('fotorama');
        return fotorama.show('<');
      case Auto.TopLeft:
        return endZoom();
      case Auto.BottomRight:
        return zoomToCorner(0, 0);
    }
  };

  autoNext = function() {
    var fotorama;
    switch (autoState) {
      case Auto.None:
        return zoomToCorner(0, 0);
      case Auto.TopLeft:
        return zoomToCorner(1, 1);
      case Auto.BottomRight:
        fotorama = $('.fotorama').data('fotorama');
        return fotorama.show('>');
    }
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
      case 32:
        spaceHeld = true;
        autoState = Auto.None;
        console.log("autoState: None (space)");
        break;
      case 90:
        autoState = Auto.None;
        fotorama = $('.fotorama').data('fotorama');
        fotorama.show('<');
        break;
      case 88:
        autoState = Auto.None;
        fotorama = $('.fotorama').data('fotorama');
        fotorama.show('>');
        break;
      case 81:
        zoomToCorner(0, 0);
        break;
      case 87:
        zoomToCorner(1, 0);
        break;
      case 65:
        zoomToCorner(0, 1);
        break;
      case 83:
        zoomToCorner(1, 1);
        break;
      case 68:
        autoPrev();
        break;
      case 70:
        autoNext();
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

  fotorama.on('fotorama:showend', function(e, fotorama, extra) {
    if (window.hasOwnProperty('onPage')) {
      window.onPage(fotorama.activeIndex + 1);
    }
    switch (autoStateOnShowEnd) {
      case Auto.BottomRight:
        zoomToCorner(1, 1);
    }
    return autoStateOnShowEnd = Auto.None;
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
    $("body").append("<a class=\"box indexbox\" href=\"../\"></a>");
  }

  console.log("preloading images: " + preloadImages);

  if (preloadImages) {
    $("body").append("<div id=\"preloadbar\"><div id=\"preloadbarinner\"></div></div>");
    loadedImages = {};
    nextLoadIndex = 0;
    loadNextImage = function() {
      var img, percentage;
      percentage = Math.floor(100 * (nextLoadIndex + 1) / comicImages.length);
      $('#preloadbarinner').width(percentage + "%");
      if (nextLoadIndex < comicImages.length) {
        img = new Image();
        img.onload = function() {
          return loadNextImage();
        };
        img.onerror = function() {
          nextLoadIndex -= 1;
          console.log("retrying " + comicImages[nextLoadIndex]);
          return loadNextImage();
        };
        loadedImages[comicImages[nextLoadIndex]] = img;
        console.log("Preloading " + comicImages[nextLoadIndex]);
        img.src = comicImages[nextLoadIndex];
        return nextLoadIndex += 1;
      } else {
        console.log("Preloading complete.");
        return $('#preloadbar').fadeOut(2500);
      }
    };
    loadNextImage();
  }

}).call(this);
