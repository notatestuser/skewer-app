#####

app = window.app = angular.module('AngularSFDemo', [
   'AngularForce',
   'AngularForceObjectFactory',
   'SFModels',
   'ui.bootstrap.dropdownToggle'
])

# ⚑
# TODO: Figure out why this has to be attached to the window
window.SFConfig = SFGlobals.getSFConfig()
window.SFConfig.maxListSize = 25

app.constant "SFConfig", SFConfig

app.config ($routeProvider) ->
   $routeProvider

   # app routes
   .when('/',
      controller: 'HomeCtrl'
      templateUrl: 'partials/home.html'
   )

   # contacts editor routes
   .when('/contacts',
      controller: 'ContactListCtrl'
      templateUrl: 'partials/contact/list.html'
   )
   .when('/view/:contactId',
      controller: 'ContactViewCtrl'
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
