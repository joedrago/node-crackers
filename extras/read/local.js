
// Function used to query the read state and modify it. (pass an empty object to simply query).
function readRequest(req, cb)
{
    // Find out what path we are.
    var dir = "";
    $('body').each(function() {
        dir = $(this).data('dir');
    });

    // $.post("/read.php?p=" + dir, JSON.stringify(req), onReadResponse, 'json');
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
                var progress = 0;
                if(e != undefined) {
                    progress = e.progress;
                }
                t.data("progress", progress);
                if(progress > 100) {
                    progress = 0;
                }
                bar.width(String(progress) + "%");
            }
        });

        if(cb) {
            cb(data);
        }
    }
    function onReadError(xhr, textStatus, errorThrown ) {
        this.tryCount++;
        if (this.tryCount <= this.retryLimit) {
            console.log("retrying read request ...");
            $.ajax(this);
            return;
        }
        return;
    }
    $.ajax({
        type: "POST",
        url: "/read.php?p=" + dir,
        data: JSON.stringify(req),
        success: onReadResponse,
        error: onReadError,
        dataType: 'json',
        tryCount : 0,
        retryLimit : 3,
    });
}
window.readRequest = readRequest;
