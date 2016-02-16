/**
 * Web Worker to load user data in a separate thread.
 */

// Maximum number of times the http POST is attempted
max_retries = 60

// Interval between HTTP POST retries
retry_interval_msec = 1000

// Callback for messages from the main thread
onmessage = function(e){
    // CSRF token
    var token = e.data.token
    do_get(token, 0);
}

// Perform the HTTP GET
do_get = function(token, retry_count) {
  var req = new XMLHttpRequest();
  req.onreadystatechange = function(e) {
    if (req.readyState == XMLHttpRequest.DONE) {
      if (req.status == 0) {
        // Network error, retry up to max_retries times
        if (retry_count < max_retries) {
            setTimeout(do_get, retry_interval_msec, token, retry_count + 1);
        }
        else {
            // Unrecoverable failure
            postMessage({status: req.status});
        }
      }
      else {
        // Success (actual HTTP status may indicate an error response, main thread handles it)
        jsonResponse = JSON.parse(req.responseText);
        postMessage({status: req.status, response: jsonResponse});
      }
    }
  };
  req.open("GET", "/api/user_data.json");
  req.setRequestHeader("X-CSRF-Token", token);
  req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  req.send();
}