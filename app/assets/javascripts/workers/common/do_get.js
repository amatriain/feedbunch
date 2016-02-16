/**
 * Perform an HTTP GET from a web worker
 * Built-in retrying if the network is down
 */

// Maximum number of times the http GET is attempted
max_retries = 60;

// Interval between HTTP GET retries
retry_interval_msec = 1000;

// Perform the HTTP GET
do_get = function(url, token, retry_count) {
  var req = new XMLHttpRequest();
  req.onreadystatechange = function(e) {
    if (req.readyState == XMLHttpRequest.DONE) {
      if (req.status == 0) {
        // Network error, retry up to max_retries times
        if (retry_count < max_retries) {
          setTimeout(do_get, retry_interval_msec, url, token, retry_count + 1);
        }
        else {
          // Unrecoverable failure
          postMessage({status: req.status});
        }
      }
      else {
        // Success (actual HTTP status may indicate an error response, main thread handles it)
        data = {status: req.status};
        if (req.responseText){
          data["response"] = JSON.parse(req.responseText);
        }
        postMessage(data);
      }
    }
  };
  req.open("GET", url);
  req.setRequestHeader("X-CSRF-Token", token);
  req.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
  req.send();
}