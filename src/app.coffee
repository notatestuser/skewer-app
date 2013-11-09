#####

app = angular.module('AngularSFDemo', [
   'AngularForce',
   'AngularForceObjectFactory',
   'SFModels',
   'ui.bootstrap.dropdownToggle'])

SFConfig = getSFConfig()
SFConfig.maxListSize = 25

app.constant "SFConfig", SFConfig

app.config ($routeProvider) ->
   $routeProvider.when("/",
      controller: HomeCtrl
      templateUrl: "partials/home.html"
   )
   .when("/login",
      controller: LoginCtrl
      templateUrl: "partials/login.html"
   )
   .when("/logout",
      controller: LoginCtrl
      templateUrl: "partials/logout.html"
   )
   .when("/callback",
      controller: CallbackCtrl
      templateUrl: "partials/callback.html"
   )
   .when("/contacts",
      controller: ContactListCtrl
      templateUrl: "partials/contact/list.html"
   )
   .when("/view/:contactId",
      controller: ContactViewCtrl
      templateUrl: "partials/contact/view.html"
   )
   .when("/edit/:contactId",
      controller: ContactDetailCtrl
      templateUrl: "partials/contact/edit.html"
   )
   .when("/new",
      controller: ContactDetailCtrl
      templateUrl: "partials/contact/edit.html"
   )
   .otherwise redirectTo: "/"

#####

###
Describe Salesforce object to be used in the app. For example: Below AngularJS factory shows how to describe and
create an 'Contact' object. And then set its type, fields, where-clause etc.

PS: This module is injected into ListCtrl, EditCtrl etc. controllers to further consume the object.
###

#Describe the contact object
HomeCtrl = ($scope, AngularForce, $location, $route) ->
   isOnline = AngularForce.isOnline()
   isAuthenticated = AngularForce.authenticated()

   #Offline support (only for Cordova)
   #First check if we are online, then check if we are already authenticated (usually happens in Cordova),
   #If Both online and authenticated(Cordova), go directly to /contacts view. Else show login page.
   unless isOnline
      unless isAuthenticated #MobileWeb
         return $location.path("/login")
      else #Cordova
         return $location.path("/contacts/")

   #If in visualforce, directly login
   if AngularForce.inVisualforce
      $location.path "/login"
   else if AngularForce.refreshToken #If web, try to relogin using refresh-token
      AngularForce.login ->
         $location.path "/contacts/"
         $scope.$apply() #Required coz sfdc uses jquery.ajax

   else
      $location.path "/login"

LoginCtrl = ($scope, AngularForce, $location) ->
   #Usually happens in Cordova
   return $location.path("/contacts/")  if AngularForce.authenticated()
   $scope.login = ->

      #If in visualforce, 'login' = initialize entity framework
      if AngularForce.inVisualforce
         AngularForce.login ->
            $location.path "/contacts/"

      else
         AngularForce.login()

   $scope.isLoggedIn = ->
      AngularForce.authenticated()

   $scope.logout = ->
      AngularForce.logout ->

         #Now go to logout page
         $location.path "/logout"
         $scope.$apply()

CallbackCtrl = ($scope, AngularForce, $location) ->
   AngularForce.oauthCallback document.location.href

   #Note: Set hash to empty before setting path to /contacts to keep the url clean w/o oauth info.
   #..coz oauth CB returns access_token in its own hash making it two hashes (1 from angular,
   # and another from oauth)
   $location.hash ""
   $location.path "/contacts"

ContactListCtrl = ($scope, AngularForce, $location, Contact) ->
   return $location.path("/home")  unless AngularForce.authenticated()
   $scope.searchTerm = ""
   $scope.working = false
   Contact.query ((data) ->
      $scope.contacts = data.records
      $scope.$apply() #Required coz sfdc uses jquery.ajax
   ), (data) ->
      alert "Query Error"

   $scope.isWorking = ->
      $scope.working

   $scope.doSearch = ->
      Contact.search $scope.searchTerm, ((data) ->
         $scope.contacts = data
         $scope.$apply() #Required coz sfdc uses jquery.ajax
      ), (data) ->

   $scope.doView = (contactId) ->
      console.log "doView"
      $location.path "/view/" + contactId

   $scope.doCreate = ->
      $location.path "/new"

ContactCreateCtrl = ($scope, $location, Contact) ->
   $scope.save = ->
      Contact.save $scope.contact, (contact) ->
         c = contact
         $scope.$apply ->
            $location.path "/view/" + c.Id

ContactViewCtrl = ($scope, AngularForce, $location, $routeParams, Contact) ->
   AngularForce.login ->
      Contact.get
         id: $routeParams.contactId
      , (contact) ->
         self.original = contact
         $scope.contact = new Contact(self.original)
         $scope.$apply() #Required coz sfdc uses jquery.ajax

ContactDetailCtrl = ($scope, AngularForce, $location, $routeParams, Contact) ->
   self = this
   if $routeParams.contactId
      AngularForce.login ->
         Contact.get
            id: $routeParams.contactId
         , (contact) ->
            self.original = contact
            $scope.contact = new Contact(self.original)
            $scope.$apply() #Required coz sfdc uses jquery.ajax
   else
      $scope.contact = new Contact()

   #$scope.$apply();
   $scope.isClean = ->
      angular.equals self.original, $scope.contact

   $scope.destroy = ->
      self.original.destroy (->
         $scope.$apply ->
            $location.path "/contacts"

      ), (errors) ->
         alert "Could not delete contact!\n" + JSON.parse(errors.responseText)[0].message

   $scope.save = ->
      if $scope.contact.Id
         $scope.contact.update ->
            $scope.$apply ->
               $location.path "/view/" + $scope.contact.Id
      else
         Contact.save $scope.contact, (contact) ->
            c = contact
            $scope.$apply ->
               $location.path "/view/" + c.Id or c.id

   $scope.doCancel = ->
      if $scope.contact.Id
         $location.path "/view/" + $scope.contact.Id
      else
         $location.path "/contacts"

