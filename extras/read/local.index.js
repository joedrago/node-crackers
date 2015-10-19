// jquery-dropdown
jQuery&&function($){function t(t,e){var n=t?$(this):e,d=$(n.attr("data-jq-dropdown")),a=n.hasClass("jq-dropdown-open");if(t){if($(t.target).hasClass("jq-dropdown-ignore"))return;t.preventDefault(),t.stopPropagation()}else if(n!==e.target&&$(e.target).hasClass("jq-dropdown-ignore"))return;o(),a||n.hasClass("jq-dropdown-disabled")||(n.addClass("jq-dropdown-open"),d.data("jq-dropdown-trigger",n).show(),r(),d.trigger("show",{jqDropdown:d,trigger:n}))}function o(t){var o=t?$(t.target).parents().addBack():null;if(o&&o.is(".jq-dropdown")){if(!o.is(".jq-dropdown-menu"))return;if(!o.is("A"))return}$(document).find(".jq-dropdown:visible").each(function(){var t=$(this);t.hide().removeData("jq-dropdown-trigger").trigger("hide",{jqDropdown:t})}),$(document).find(".jq-dropdown-open").removeClass("jq-dropdown-open")}function r(){var t=$(".jq-dropdown:visible").eq(0),o=t.data("jq-dropdown-trigger"),r=o?parseInt(o.attr("data-horizontal-offset")||0,10):null,e=o?parseInt(o.attr("data-vertical-offset")||0,10):null;0!==t.length&&o&&t.css(t.hasClass("jq-dropdown-relative")?{left:t.hasClass("jq-dropdown-anchor-right")?o.position().left-(t.outerWidth(!0)-o.outerWidth(!0))-parseInt(o.css("margin-right"),10)+r:o.position().left+parseInt(o.css("margin-left"),10)+r,top:o.position().top+o.outerHeight(!0)-parseInt(o.css("margin-top"),10)+e}:{left:t.hasClass("jq-dropdown-anchor-right")?o.offset().left-(t.outerWidth()-o.outerWidth())+r:o.offset().left+r,top:o.offset().top+o.outerHeight()+e})}$.extend($.fn,{jqDropdown:function(r,e){switch(r){case"show":return t(null,$(this)),$(this);case"hide":return o(),$(this);case"attach":return $(this).attr("data-jq-dropdown",e);case"detach":return o(),$(this).removeAttr("data-jq-dropdown");case"disable":return $(this).addClass("jq-dropdown-disabled");case"enable":return o(),$(this).removeClass("jq-dropdown-disabled")}}}),window.jqshow=t,$(document).on("click.jq-dropdown","[data-jq-dropdown]",t),window.jqhide=o,$(document).on("click.jq-dropdown",o),window.jqresize=r,$(window).on("resize",r)}(jQuery);

// Draw the progress bars above each entry.
$(".entry").each(function() {
    var t = $(this);
    var d = t.data('dir');
    if(d != undefined) {
        t.prepend("<div class=\"progressbar\"><div class=\"progressbarinner\"></div></div>");
    }
});

$('body').append(
    "<div id=\"contextmenu\" class=\"jq-dropdown jq-dropdown-tip\">"+
        "<ul class=\"jq-dropdown-menu\">"+
            "<li><a class=\"menuitem\" onclick=\"window.markRead()\">Mark Read</a></li>"+
            "<li class=\"jq-dropdown-divider\"></li>"+
            "<li><a class=\"menuitem\" onclick=\"window.markUnread()\">Mark Unread</a></li>"+
            "<li class=\"jq-dropdown-divider\"></li>"+
            "<li><a class=\"menuitem\" onclick=\"window.toggleIgnore()\">Toggle Ignore</a></li>"+
        "</ul>"+
    "</div>");

function createSection(title, progress) {
    var elem = $("<div class=\"sorted sortowned\"><div class=\"interestsection\">"+title+":</div>");
    $("#entries").append(elem);
    elem.data("title", " "); // So that it sorts before its target
    elem.data("progress", progress);
}

// Add a new sort type.
window.sorts.push(
  {
    name: 'By Interest',
    pre: function() {
        var sawAvailable = false;
        var sawContinue = false;
        var sawFinished = false;
        var sawIgnored = false;
        $(".sorted").each(function() {
            var t = $(this);
            var p = t.data("progress");
            if(p == 100) {
                sawFinished = true;
            } else if(p == -1) {
                sawIgnored = true;
            } else if(p == 0) {
                sawAvailable = true;
            } else {
                sawContinue = true;
            }
        });
        if(sawAvailable) {
            createSection("Available", 0);
        }
        if(sawContinue) {
            createSection("Continue", 99);
        }
        if(sawFinished) {
            createSection("Finished", 100);
        }
        if(sawIgnored) {
            createSection("Ignored", -1);
        }
    },
    func: function (a, b) {
      ca = parseInt($(a).data('progress'));
      cb = parseInt($(b).data('progress'));
      if(ca ==  cb) return window.sorts[0].func(a, b);
      if(ca == 100) return  1;
      if(cb == 100) return -1;
      if(ca  <  cb) return  1;
      if(ca  >  cb) return -1;
      return 0;
    }
  }
);

window.toggleIgnore = function() {
    window.readRequest({ ignore: window.dropdownDir }, function() {
        window.resort();
    });
}

window.markRead = function() {
    if(!confirm("Are you sure you want to mark all of '"+window.dropdownDir+"' as read?")) {
        return;
    }
    window.readRequest({ mark: window.dropdownDir }, function() {
        window.resort();
    });
}

window.markUnread = function() {
    if(!confirm("Are you sure you want to mark all of '"+window.dropdownDir+"' as unread?")) {
        return;
    }
    window.readRequest({ unmark: window.dropdownDir }, function() {
        window.resort();
    });
}

var oldOnLocalLoaded = window.onLocalLoaded;
window.onLocalLoaded = function() {
    console.log("waiting for read progress to load...");
}

// Query the current read state.
window.readRequest({}, function() {
    // Find out what path we are.
    var dir = "";
    $('body').each(function() {
        dir = $(this).data('dir');
    });

    if(dir === "") {
        window.sort(window.sorts.length - 1);
    }

    $(".entry").each(function() {
        var t = $(this);
        var d = t.data('dir');
        var p = t.data('progress');
        if((d != undefined)) {
            elem = $("<span data-jq-dropdown=\"#contextmenu\" class=\"menubutton\">[Actions]</span>");
            elem.click(function(event) {
                window.dropdownDir = d;
                console.log("event", event);
                window.jqshow.call($(this), event);
            });
            t.append(elem);
        }
    });
    if(oldOnLocalLoaded) {
            oldOnLocalLoaded();
    }
});
