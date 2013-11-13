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
window.SFConfig = SFGlobals.getSFConfig()
window.SFConfig.maxListSize = 25

app.constant 'SFConfig', SFConfig

app.config ['$routeProvider', 'platformProvider',
($routeProvider, platformProvider) ->
   platformProvider.set('https://goinstant.net/sdavyson/Skewer')

   $routeProvider

   # app routes
   .when('/',
      controller: 'HomeCtrl'
      templateUrl: 'partials/home.html'
   )

   # the editor
   .when('/designer/:opportunityId',
      controller: 'PitchEditorCtrl'
      templateUrl: 'partials/editor.html'
   )

   # contacts editor routes
   .when('/contacts',
      controller: 'OpportunityListCtrl'
      templateUrl: 'partials/contact/list.html'
   )
   .when('/view/:contactId',
      controller: 'ContactViewCtrl'
      templateUrl: 'partials/contact/view.html'
   )
   .when('/viewOpp/:opportunityId',
      controller: 'OpportunityViewCtrl'
      templateUrl: 'partials/contact/view.html'
   )
   .when('/edit/:contactId',
      controller: 'ContactDetailCtrl'
      templateUrl: 'partials/contact/edit.html'
   )
   .when('/new',
      controller: 'ContactDetailCtrl'
      templateUrl: 'partials/contact/edit.html'
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

]
