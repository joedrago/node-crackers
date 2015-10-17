// Draw the progress bars above each entry.
$(".entry").each(function() {
    var t = $(this);
    var d = t.data('dir');
    if(d != undefined) {
        t.prepend("<div class=\"progressbar\"><div class=\"progressbarinner\"></div></div>");
    }
});

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
        $(".sorted").each(function() {
            var t = $(this);
            var p = t.data("progress");
            if(p == 100) {
                sawFinished = true;
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

window.markread = function(dir) {
    if(!confirm("Are you sure you want to mark all of '"+dir+"' as read?")) {
        return;
    }
    window.readRequest({ mark: dir }, function() {
        window.resort();
    });
}

window.markunread = function(dir) {
    if(!confirm("Are you sure you want to mark all of '"+dir+"' as unread?")) {
        return;
    }
    window.readRequest({ unmark: dir }, function() {
        window.resort();
    });
}

// Query the current read state.
window.readRequest({}, function() {
    if(dir === "") {
        window.sort(window.sorts.length - 1);
    }

    $(".entry").each(function() {
        var t = $(this);
        var d = t.data('dir');
        var p = t.data('progress');
        if((d != undefined)) {
            var elem = $("<span class=\"actiontext\">Mark as: </span>");
            t.append(elem);
            elem = $("<a class=\"actions\">Read</a>");
            elem.click(function(event) {
                window.markread(d);
            });
            t.append(elem);
            var elem = $("<span class=\"actiontext\"> / </span>");
            t.append(elem);
            elem = $("<a class=\"actions\">Unread</a>");
            elem.click(function(event) {
                window.markunread(d);
            });
            t.append(elem);
        }
    });
});
