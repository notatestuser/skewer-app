# Services

# ... but first some constants
APEX_REST_PITCH_CREATE_URL = 'https://pitch-developer-edition.na15.force.com/services/apexrest/skewerapp/SkewerCreate'
APEX_REST_PITCH_UPDATE_URL = 'https://pitch-developer-edition.na15.force.com/services/apexrest/skewerapp/SkewerUpdate'

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
   generateShortUrlToSkewer: (roomId, opportunityId, pitchId) ->
      data =
         roomId: roomId
         pitchId: pitchId
         opportunityId: opportunityId
      $http.post '/shortener', data
])

.factory('pitchesService', ['$http', 'SFConfig', ($http, SFConfig) ->
   convertComponentsToFileIdList: (components=[]) ->
      _.compact(_.pluck components, 'id').toString()
   createPitchInSalesforce: (roomId, opportunityId, fileIdList=[], callbackFn) ->
      data = p:
         roomId: roomId
         fileList: fileIdList
         opportunityId: opportunityId
         userId: SFConfig.client.userId
      paramMap =
         'SalesforceProxy-Endpoint': APEX_REST_PITCH_CREATE_URL
      SFConfig.client.apexrest(
         '/PitchCreate',
         callbackFn,
         null,
         'PUT',
         JSON.stringify(data), paramMap)
   updatePitchShortUrlInSalesforce: (pitchId, shortURL, callbackFn) ->
      data = p:
         id: pitchId
         shortURL: shortURL
      paramMap =
         'SalesforceProxy-Endpoint': APEX_REST_PITCH_UPDATE_URL
      SFConfig.client.apexrest(
         '/SkewerUpdate',
         callbackFn,
         null,
         'PUT',
         JSON.stringify(data), paramMap)
   trackPageViewInSalesforce: (roomId, opportunityId, pitchId) ->
      data = p: id: pitchId
      $http
         method: 'PUT'
         url: '/proxy/?_track_page_view'
         data: data
         headers: 'salesforceproxy-endpoint': APEX_REST_PITCH_UPDATE_URL
])

.factory('shareService', ['$location', 'pitchesService', ($location, pitchesService) ->
   store =
      opportunityId: null
      fileIdList: null
      roomId: null
   {
      storeAttributesAndGoToSharePage: (roomId, opportunityId, components=[]) ->
         store.fileIdList = pitchesService.convertComponentsToFileIdList components
         store.opportunityId = opportunityId
         store.roomId = roomId
         $location.path "/skewer/share"
      get: (key) ->
         return null if not store[key]
         store[key]
   }
])
