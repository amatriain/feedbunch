/**
 * Web Worker to update the state of a single entry in a separate thread.
 */

// Maximum number of times the http POST is attempted
max_retries = 60

// Interval between HTTP POST retries
retry_interval_msec = 1000

// Callback for messages from the main thread
onmessage = function(e){
    // CSRF token
    var token = e.data.token

    // ID of the entry
    var id = e.data.id

    // New state for the entry, "read" or "unread"
    var state = e.data.state

    // ID of the feed, if the user clicked on the feed link in the entry.
    // Not used in this worker, but returned to the main thread so it knows how to
    // act when receiving the message callback.
    var feed_id = e.data.feed_id

    do_post(token, id, state, feed_id, 0);
}

// Perform the HTTP POST
do_post = function(token, id, state, feed_id, retry_count) {
    var req = new XMLHttpRequest();
    req.onreadystatechange = function(e) {
        if (req.readyState == XMLHttpRequest.DONE) {
            if (req.status == 0) {
                // Network error, retry up to max_retries times
                if (retry_count < max_retries) {
                    setTimeout(do_post, retry_interval_msec, token, id, state, feed_id, retry_count + 1);
                }
                else {
                    // Unrecoverable failure
                    postMessage({status: req.status, id: id, feed_id: feed_id});
                }
            }
            else {
                // Success (actual HTTP status may indicate an error response, main thread handles it)
                postMessage({status: req.status, id: id, feed_id: feed_id});
            }
        }
    };
    req.open("PUT", "/api/entries/update.json");
    req.setRequestHeader("X-CSRF-Token", token);
    req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    req.send( JSON.stringify( {entry: {id: id, state: state}} ) );
}