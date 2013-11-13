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
            prev.push
               name:     current.Name
               linkHref: current.skewerapp__Tracked_Link__c
               content:  current.skewerapp__Source__c or current.skewerapp__Text__c
            prev
         , []
         callback null, obj
      ), (data) ->
         alert "Query Error"
])
