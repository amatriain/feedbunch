/**
 * Perform an HTTP PUT from a web worker
 * Built-in retrying if the network is down
 */

// Maximum number of times the http PUT is attempted
max_retries = 60;

// Interval between HTTP PUT retries
retry_interval_msec = 1000;

// Perform the HTTP PUT
do_put = function(operation, url, token, data, retry_count) {
  var req = new XMLHttpRequest();
  
  req.onreadystatechange = function(e) {
    if (req.readyState == XMLHttpRequest.DONE) {
      if (req.status == 0) {
        // Network error, retry up to max_retries times
        if (retry_count < max_retries) {
          setTimeout(do_put, retry_interval_msec, operation, url, token, data, retry_count + 1);
        }
        else {
          // Unrecoverable failure
          postMessage({operation: operation, status: req.status, params: data});
        }
      }
      else {
        // Success (actual HTTP status may indicate an error response, main thread handles it)
        postMessage({operation: operation, status: req.status, params: data});
      }
    }
  };
  req.open("PUT", url);
  req.setRequestHeader("X-CSRF-Token", token);
  req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  req.send( JSON.stringify(data) );
}