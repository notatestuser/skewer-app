#####

app = window.app = angular.module('AngularSFDemo', [
   'AngularForce'
   'AngularForceObjectFactory'
   'goinstant'
   'ForceModels'
   'skewer.services'
   'ui.bootstrap.dropdownToggle'
])

# ⚑
# TODO: Figure out why this has to be attached to the window
SFConfig = window.SFConfig = SFGlobals.getSFConfig()
SFConfig.maxListSize = 25

app.constant('SFConfig', SFConfig)
app.constant('GoInstantAppUrl', 'https://goinstant.net/sdavyson/Skewer')

.config(['$windowProvider', '$routeProvider', 'platformProvider', 'GoInstantAppUrl', 'GoInstantRoomIdProvider',
($window, $routeProvider, platformProvider, GoInstantAppUrl, GoInstantRoomIdProvider) ->
   ### GoInstant platform init ###

   # do we already have a room id?
   rooms = []
   matches = $window.$get().location.hash.match(/\/([a-z0-9]+)$/)
   if matches
      rooms.push matches[1]
   else
      # no. generate one
      rooms.push Math.random().toString(36).substring(2)
   GoInstantRoomIdProvider.setRoomId roomId = rooms[0]
   console.log "GoInstant room ID configured as #{roomId}"

   platformProvider.set GoInstantAppUrl, rooms: rooms

   ### Route resolver hashes ###

   resolvePageBrandingForEditor =
      salesforceOrgSiteHost: ['$q', '$rootScope', '$route', 'AngularForce', 'Opportunity',
      ($q, $rootScope, $route, AngularForce, Opportunity) ->
         deferred = $q.defer()
         {opportunityId} = $route.current.params
         if AngularForce.authenticated()
            Opportunity().get id: opportunityId, (opportunity={}) ->
               $rootScope.$apply ->
                  $rootScope.salesforceOrgSiteHost = opportunity.getskewer__Skewer_Site_URL__c
                  deferred.resolve $rootScope.salesforceOrgSiteHost
         else
            deferred.resolve ''
         deferred.promise
      ]
      pageBrandingData: ['$q', '$rootScope', 'AngularForce', 'pageBrandingService',
      ($q, $rootScope, AngularForce, pageBrandingService) ->
         deferred = $q.defer()
         if AngularForce.authenticated()
            pageBrandingService.fetchPageBrandingDescriptor (err, brandingData) ->
               $rootScope.$apply ->
                  deferred.resolve brandingData
         else
            deferred.resolve {}
         deferred.promise
      ]

   ### Route configuration ###

   $routeProvider

   # app routes
   .when('/',
      controller: 'HomeCtrl'
      templateUrl: 'partials/home.html'
   )

   # the editor
   .when('/skewer/:opportunityId/:roomId',
      controller: 'SkewerCanvasCtrl'
      templateUrl: 'partials/editor.html'
      resolve: resolvePageBrandingForEditor
      showBranding: true
   )

   # the editor
   .when('/skewer/:opportunityId/:pitchId/:roomId',
      controller: 'SkewerCanvasCtrl'
      templateUrl: 'partials/editor.html'
      resolve: resolvePageBrandingForEditor
      showBranding: true
   )

   # share route
   .when('/skewer/share',
      controller: 'SkewerShareCtrl'
      templateUrl: 'partials/share.html'
      resolve:
         salesforcePitchId: ['$route', '$q', '$rootScope', 'shareService', 'pitchesService',
         ($route, $q, $rootScope, shareService, pitchesService) ->
            deferred = $q.defer()
            [roomId, fileIdList, opportunityId] = [
               shareService.get('roomId'),
               shareService.get('fileIdList'),
               shareService.get('opportunityId')
            ]
            {salesforceOrgSiteHost} = $rootScope
            pitchesService.createPitchInSalesforce salesforceOrgSiteHost, roomId, opportunityId, fileIdList,
            (pitchId) ->
               $rootScope.$apply ->
                  deferred.resolve pitchId
            deferred.promise
         ]
      showBranding: true
   )

   # contacts editor routes
   .when('/contacts',
      controller: 'OpportunityListCtrl'
      templateUrl: 'partials/contact/list.html'
   )

   # auth routes
   .when('/login',
      controller: 'LoginCtrl'
      templateUrl: 'partials/login.html'
   )
   .when('/logout',
      controller: 'LoginCtrl'
      templateUrl: 'partials/logout.html'
   )
   .when('/callback',
      controller: 'CallbackCtrl'
      templateUrl: 'partials/callback.html'
   )

   .otherwise redirectTo: '/'
])

.run(['$rootScope', '$route',
($rootScope, $route) ->
    $rootScope.$on '$routeChangeSuccess', (event, current) ->
      $rootScope.isBrandedRoute = $route.current?.$$route?.showBranding
])
