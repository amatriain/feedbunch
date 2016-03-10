/**
 * Perform an HTTP DELETE from a web worker
 * Built-in retrying if the network is down
 */

// Maximum number of times the http DELETE is attempted
max_retries = 60;

// Interval between HTTP DELETE retries
retry_interval_msec = 1000;

var req = new XMLHttpRequest();

// Perform the HTTP DELETE
do_delete = function(operation, url, token, data, retry_count) {
  req.onreadystatechange = function(e) {
    if (req.readyState == XMLHttpRequest.DONE) {
      if (req.status == 0) {
        // Network error, retry up to max_retries times
        if (retry_count < max_retries) {
          setTimeout(do_delete, retry_interval_msec, operation, url, token, data, retry_count + 1);
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
  req.open("DELETE", url);
  req.setRequestHeader("X-CSRF-Token", token);
  req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  req.send();
}