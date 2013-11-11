# Services

angular.module('skewer.services', [])

.factory('contentAssetsService', ['$http', '$q', '$timeout', 'Assets',
($http, $q, $timeout, Assets) ->
   # type will be something like 'text', 'image', etc...
   getContentItemsForType: (type, callback) ->
      # do a service call
      Assets(type)
      .query ((data) ->
         obj = data.records.reduce (prev, current) ->
            prev[current.Link__c] = current.Name
            prev
         , {}
         callback null, obj
      ), (data) ->
         alert "Query Error"
])
