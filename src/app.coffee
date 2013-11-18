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

.config ($compileProvider) ->
   $compileProvider.urlSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)

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
   platformProvider.set GoInstantAppUrl, rooms: rooms
   console.log "Default GoInstant room ID configured as #{roomId}"

   ### Route resolver hashes ###

   resolvePageBrandingForEditor =
      salesforceOpportunity: ['$q', '$rootScope', '$route', 'AngularForce', 'Opportunity',
      ($q, $rootScope, $route, AngularForce, Opportunity) ->
         deferred = $q.defer()
         {opportunityId} = $route.current.params
         if AngularForce.authenticated()
            Opportunity().get id: opportunityId, (opportunity={}) ->
               $rootScope.$apply ->
                  $rootScope.salesforceOrgSiteHost = opportunity.getskewer__Skewer_Site_URL__c
                  deferred.resolve opportunity
         else
            # GI will get this for us
            deferred.resolve {}
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
            # GI will get this for us
            deferred.resolve {}
         deferred.promise
      ]
      userContactDetails: ['$q', '$rootScope', 'AngularForce', 'User',
      ($q, $rootScope, AngularForce, User) ->
         deferred = $q.defer()
         if AngularForce.authenticated()
            User
            .query ((data) ->
               sfuser = data.records?[0]
               $rootScope.$apply ->
                  return deferred.reject('no sfuser available') if not sfuser
                  user =
                     id:    sfuser.Id
                     name:  sfuser.getskewer__Skewer_Name__c
                     email: sfuser.getskewer__Skewer_Email__c
                     phone: sfuser.getskewer__Skewer_Phone__c
                  deferred.resolve user
            ), (err) ->
               $rootScope.$apply ->
                  deferred.reject err
         else
            # GI will get this for us
            deferred.resolve {}
         deferred.promise
      ]

   ### Route configuration ###

   $routeProvider

   # app routes
   .when('/',
      controller: 'HomeCtrl'
      templateUrl: 'partials/home.html'
      resolve: 
         app: ($q, $rootScope, AngularForce) ->
            deferred = $q.defer()
            console.log('start cordova login')
            if AngularForce.inCordova 
               unless AngularForce.authenticated()
                  console.log('Lets authenticate')
                  AngularForce.setCordovaLoginCred ->
                     $rootScope.$apply ->
                        console.log('Ready')
                        deferred.resolve()
               else 
                  console.log('Already Has')
                  deferred.resolve()   
            else 
               console.log('Already Has')
               deferred.resolve()   
            deferred.promise
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
      showBranding: false
   )

   # model lists
   # ... list of skewers
   .when('/skewers/:opportunityId',
      controller: 'SkewerListCtrl'
      templateUrl: 'partials/skewer-list.html'
      resolve:
         sfSkewersForOpportunity: ['$q', '$rootScope', '$route', 'SFConfig', 'Skewer',
         ($q, $rootScope, $route, SFConfig, Skewer) ->
            deferred = $q.defer()
            {opportunityId} = $route.current.params
            Skewer(SFConfig.client.userId, opportunityId)
            .query ((data) ->
               $rootScope.$apply ->
                  deferred.resolve data.records
            ), (err) ->
               $rootScope.$apply ->
                  deferred.reject err
            deferred.promise
         ]
   )

   # ... list of opportunities
   .when('/contacts',
      controller: 'OpportunityListCtrl'
      templateUrl: 'partials/contact/list.html'
      resolve:
         sfOpportunities: ['$q', '$rootScope', 'Opportunity',
         ($q, $rootScope, Opportunity) ->
            deferred = $q.defer()
            Opportunity()
            .query ((data) ->
               $rootScope.$apply ->
                  deferred.resolve data.records
            ), (err) ->
               $rootScope.$apply ->
                  deferred.reject err
            deferred.promise
         ]
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
      templateUrl: 'partials/home.html'
   )

   .otherwise redirectTo: '/'
])

.run(['$rootScope', '$route', '$location',
($rootScope, $route, $location) ->
   $rootScope.hostedAppRootUrl = 'https://app.getskewer.com'

   $rootScope.navigateBackHome = ->
      $location.path '/login'

   $rootScope.$on '$routeChangeSuccess', (event, current) ->
      $rootScope.isBrandedRoute = $route.current?.$$route?.showBranding
])
