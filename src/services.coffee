# Services

# ... but first some constants
APEX_REST_PITCH_CREATE_PATH = '/services/apexrest/getskewer/SkewerCreate'
APEX_REST_PITCH_UPDATE_PATH = '/services/apexrest/getskewer/SkewerUpdate'
#####

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
               linkHref: current.getskewer__Tracked_Link__c
               content:  current.getskewer__Source__c or current.getskewer__Text__c
            prev
         , []
         callback null, obj
      ), (data) ->
         alert "Query Error"
])

.factory('pageBrandingService', ['Setting', (Setting) ->
   fetchPageBrandingDescriptor: (callback) ->
      Setting
      .query ((data) ->
         setting = data.records?[0]
         return callback('no settings available') if not setting
         obj =
            pageBgColour: setting.getskewer__Page_Background_Colour__c
            barBgColour:  setting.getskewer__Logo_Bar_Background_Colour__c
            textColour:   setting.getskewer__Text_Colour__c
            logoSrcUrl:   setting.getskewer__Logo_Link__c
         callback? null, obj
      ), (err) ->
         alert "Query Error"
         callback? err
])

.factory('pitchesService', ['$http', 'SFConfig', ($http, SFConfig) ->
   getServiceUrlFn = (orgSiteHost, servicePath) ->
      console.log("orgSiteHost is #{orgSiteHost}")
      "https://#{orgSiteHost}#{servicePath}"
   {
      convertComponentsToFileIdList: (components=[]) ->
         _.compact(_.pluck components, 'id').toString()
      createPitchInSalesforce: (orgSiteHost, roomId, opportunityId, fileIdList, callbackFn) ->
         data = p:
            roomId: roomId
            opportunityId: opportunityId
            userId: SFConfig.client.userId
         data.p.fileList = fileIdList if _.isString(fileIdList)
         paramMap =
            'SalesforceProxy-Endpoint': getServiceUrlFn(orgSiteHost, APEX_REST_PITCH_CREATE_PATH)
         SFConfig.client.apexrest(
            '/SkewerCreate',
            callbackFn,
            null,
            'PUT',
            JSON.stringify(data), paramMap)
      updatePitchShortUrlInSalesforce: (orgSiteHost, pitchId, shortURL, callbackFn) ->
         data = p:
            id: pitchId
            shortURL: shortURL
         paramMap =
            'SalesforceProxy-Endpoint': getServiceUrlFn(orgSiteHost, APEX_REST_PITCH_UPDATE_PATH)
         SFConfig.client.apexrest(
            '/SkewerUpdate',
            callbackFn,
            null,
            'PUT',
            JSON.stringify(data), paramMap)
      trackPageViewInSalesforce: (orgSiteHost, roomId, opportunityId, pitchId) ->
         data = p: id: pitchId
         $http
            method: 'PUT'
            url: '/proxy/?_track_page_view'
            data: data
            headers: 'salesforceproxy-endpoint': getServiceUrlFn(orgSiteHost, APEX_REST_PITCH_UPDATE_PATH)
   }
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

.factory('urlShortenerService', ['$rootScope', '$http', ($rootScope, $http) ->
   generateShortUrlToSkewer: (roomId, opportunityId, pitchId) ->
      data =
         roomId: roomId
         pitchId: pitchId
         opportunityId: opportunityId
      $http.post "#{$rootScope.hostedAppRootUrl}/shortener", data
])
