(function() {

"use strict";
angular.module('fsCordova', [])
 .service('CordovaService', ['$document', '$q', '$timeout',
  function($document, $q, $timeout) {

    var d = $q.defer(),
        resolved = false;

    var self = this;
    this.ready = d.promise;

    document.addEventListener('deviceready', function() {
      resolved = true;
      d.resolve(window.cordova);
    });

    // Check to make sure we didn't miss the 
    // event (just in case)
    $timeout(function() {
      if (!resolved) {
        if (window.cordova) d.resolve(window.cordova);
      }
    }, 10);
}])
})()