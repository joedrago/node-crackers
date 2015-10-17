// Find out what path we are.
var dir = "";
$('body').each(function() {
    dir = $(this).data('dir');
});

// Function used to query the read state and modify it. (pass an empty object to simply query).
function readRequest(req, cb)
{
    $.post("/read.php?p=" + dir, JSON.stringify(req), onReadResponse, 'json');
    function onReadResponse(data) {
        if(data.hasOwnProperty("error")) {
            console.log("readRequest error:", data);
            return;
        }
        console.log("onReadResponse", data);
        $('.entry').each(function() {
            var t = $(this);
            var d = t.data('dir');
            var bar = $(t.find(".progressbarinner")[0]);
            if(d != undefined) {
                var e = data.read[d];
                var progress = 50;
                if(e != undefined) {
                    progress = e.progress;
                }
                t.data("progress", progress);
                bar.width(String(progress) + "%");
            }
        });

        if(cb) {
            cb(data);
        }
    }
}
window.readRequest = readRequest;
