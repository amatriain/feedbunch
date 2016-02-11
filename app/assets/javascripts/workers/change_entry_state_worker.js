/**
 * Web Worker to update the state of a single entry in a separate thread.
 */

onmessage = function(e){
    var req = new XMLHttpRequest();


    postMessage(e.data);
}