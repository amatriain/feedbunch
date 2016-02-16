/**
 * Web Worker to update the state of all current entries in a separate thread.
 */

// Maximum number of times the http POST is attempted
max_retries = 60

// Interval between HTTP POST retries
retry_interval_msec = 1000

// Callback for messages from the main thread
onmessage = function(e){
  // CSRF token
  var token = e.data.token

  // ID of the first entry
  var id = e.data.id

  // New state for the entry, "read" or "unread"
  var state = e.data.state

  // Is user marking a whole feed as read?
  var whole_feed = e.data.whole_feed

  // Is user marking a whole folder as read?
  var whole_folder = e.data.whole_folder

  // Is user marking all entries in all folders as read?
  var all_entries = e.data.all_entries

  do_post(token, id, state, whole_feed, whole_folder, all_entries, 0);
}

// Perform the HTTP POST
do_post = function(token, id, state, whole_feed, whole_folder, all_entries, retry_count) {
  var req = new XMLHttpRequest();
  req.onreadystatechange = function(e) {
    if (req.readyState == XMLHttpRequest.DONE) {
      if (req.status == 0) {
        // Network error, retry up to max_retries times
        if (retry_count < max_retries) {
            setTimeout(do_post, retry_interval_msec, token, id, state, whole_feed, whole_folder, all_entries, retry_count + 1);
        }
        else {
            // Unrecoverable failure
            postMessage({status: req.status});
        }
      }
      else {
        // Success (actual HTTP status may indicate an error response, main thread handles it)
        postMessage({status: req.status});
      }
    }
  };
  req.open("PUT", "/api/entries/update.json");
  req.setRequestHeader("X-CSRF-Token", token);
  req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  req.send( JSON.stringify( {entry: {id: id, state: state, whole_feed: whole_feed, whole_folder: whole_folder, all_entries: all_entries}} ) );
}