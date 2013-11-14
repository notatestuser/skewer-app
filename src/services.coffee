# Services

angular.module('skewer.services', [])

.provider('GoInstantRoomId', [ ->
   roomId: null
   setRoomId: (_roomId) ->
      @roomId = _roomId
   $get: ->
      getRoomId: => @roomId
])

.factory('contentAssetsService', ['$http', '$q', '$timeout', 'Assets',
($http, $q, $timeout, Assets) ->
   # type will be something like 'text', 'image', etc...
   getContentItemsForType: (type, callback) ->
      # do a service call
      Assets(type)
      .query ((data) ->
         obj = data.records.reduce (prev, current) ->
            prev.push
               id:       current.Id
               name:     current.Name
               linkHref: current.skewerapp__Tracked_Link__c
               content:  current.skewerapp__Source__c or current.skewerapp__Text__c
            prev
         , []
         callback null, obj
      ), (data) ->
         alert "Query Error"
])

.factory('urlShortenerService', ['$http', ($http) ->
   generateShortUrlToSkewer: (opportunityId, roomId) ->
      data =
         roomId: roomId
         opportunityId: opportunityId
      $http.post '/shortener', data
])
