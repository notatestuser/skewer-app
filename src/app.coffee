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

.config(['$windowProvider', '$routeProvider', 'platformProvider', 'GoInstantRoomIdProvider',
($window, $routeProvider, platformProvider, GoInstantRoomIdProvider) ->
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

   platformProvider.set 'https://goinstant.net/sdavyson/Skewer', rooms: rooms

   ### Route resolver hashes ###

   resolvePageBrandingForEditor =
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
      controller: 'PitchEditorCtrl'
      templateUrl: 'partials/editor.html'
      showBranding: true
      resolve: resolvePageBrandingForEditor
   )

   # the editor
   .when('/skewer/:opportunityId/:pitchId/:roomId',
      controller: 'PitchEditorCtrl'
      templateUrl: 'partials/editor.html'
      showBranding: true
      resolve: resolvePageBrandingForEditor
   )

   # share route
   .when('/skewer/share',
      controller: 'PitchShareCtrl'
      templateUrl: 'partials/share.html'
      showBranding: true
      resolve:
         salesforcePitchId: ['$route', '$q', '$rootScope', 'shareService', 'pitchesService',
         ($route, $q, $rootScope, shareService, pitchesService) ->
            deferred = $q.defer()
            [roomId, fileIdList, opportunityId] = [
               shareService.get('roomId'),
               shareService.get('fileIdList'),
               shareService.get('opportunityId')
            ]
            pitchesService.createPitchInSalesforce roomId, opportunityId, fileIdList, (pitchId) ->
               $rootScope.$apply ->
                  deferred.resolve pitchId
            deferred.promise
         ]
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
