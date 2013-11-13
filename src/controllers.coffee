###
Describe Salesforce object to be used in the app. For example: Below AngularJS factory shows how to describe and
create an 'Contact' object. And then set its type, fields, where-clause etc.

PS: This module is injected into ListCtrl, EditCtrl etc. controllers to further consume the object.
###

window.app

.controller('HomeCtrl', ($scope, AngularForce, $location, $route) ->
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
)

.controller('LoginCtrl', ($scope, AngularForce, $location, SFConfig) ->
   #Usually happens in Cordova
   return $location.path("/contacts/")  if AngularForce.authenticated()

   $scope.login = ->
      #If in visualforce, 'login' = initialize entity framework
      if AngularForce.inVisualforce
         AngularForce.login ->
            console.log "Our userId is #{SFConfig.client.userId}"
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
)

.controller('CallbackCtrl', ($scope, AngularForce, $location, SFConfig) ->
   AngularForce.oauthCallback document.location.href

   #Note: Set hash to empty before setting path to /contacts to keep the url clean w/o oauth info.
   #..coz oauth CB returns access_token in its own hash making it two hashes (1 from angular,
   # and another from oauth)
   $location.hash ""
   $location.path "/contacts"
)

.controller('PitchEditorCtrl', ($window, $scope, AngularForce, GoAngular) ->
   new GoAngular($scope, 'PitchEditorCtrl', include: ['components'])
      .initialize()

   AngularForce.login ->
      # example component:
      #  {
      #     rowScale: 1
      #     colDivide: 1
      #     type: 'image'
      #     source: '... sf file id? ...'
      #     linkHref = 'http://getskewer.com/...'
      #  }
      $scope.components = [
         rowScale:  2
         colDivide: 2
         type: 'image'
         content: 'http://i.imgur.com/wdt4Ddz.jpg'
      ]

      $scope.editorContext =
         inEditMode: yes
         aspectRatio: 1.777

      compactComponents = ->
         $scope.components = $scope.components.filter (item) -> item?
         undefined

      $scope.addComponentAfter = (index = $scope.components.length - 1) ->
         newComponents = [
            # use the same scale as the component at the given index
            rowScale:  $scope.components[index].rowScale
            colDivide: $scope.components[index].colDivide
            type: null
            content: null
         ]
         existingComponents = $scope.components
         allComponents = existingComponents.slice(0, index+1)
            .concat(newComponents.concat existingComponents.slice(index+1))
         $scope.components = allComponents
         $scope.$broadcast 'component:editme', newComponents[0], true

      $scope.removeComponentAt = (index=-1) ->
         return if not $scope.components[index]
         delete $scope.components[index]
         compactComponents()

      # GoInstant platform init
      # connectUrl = 'https://goinstant.net/sdavyson/Skewer'
      # rooms = ['room101']
      # platform.setup(connectUrl, { rooms: rooms })
)

.controller('OpportunityListCtrl', ($scope, AngularForce, $location, Opportunity, SFConfig) ->
   return $location.path("/home")  unless AngularForce.authenticated()
   $scope.searchTerm = ""
   $scope.working = false
   Opportunity().query ((data) ->
      $scope.opportunities = data.records
      $scope.$apply() #Required coz sfdc uses jquery.ajax
   ), (data) ->
      alert "Query Error"

   $scope.isWorking = ->
      $scope.working

   $scope.doSearch = ->
      Opportunity().search $scope.searchTerm, ((data) ->
         $scope.opportunities = data
         $scope.$apply() #Required coz sfdc uses jquery.ajax
      ), (data) ->

   $scope.doView = (opportunityId) ->
      console.log "doView"
      $location.path "/viewOpp/" + opportunityId

   $scope.doCreate = ->
      $location.path "/newOpp"
)

.controller('ContactListCtrl', ($scope, AngularForce, $location, Contact) ->
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
)

.controller('ContactCreateCtrl', ($scope, $location, Contact) ->
   $scope.save = ->
      Contact.save $scope.contact, (contact) ->
         c = contact
         $scope.$apply ->
            $location.path "/view/" + c.Id
)

.controller('OpportunityViewCtrl', ($scope, AngularForce, $location, $routeParams, Opportunity) ->
   AngularForce.login ->
      Opportunity().get
         id: $routeParams.opportunityId
      , (opportunity) ->
         self.original = opportunity
         $scope.opportunity = new Opportunity()(self.original)
         $scope.$apply() #Required coz sfdc uses jquery.ajax

      Pitch__c.query ((data) ->
         $scope.pitches = data.records
         $scope.$apply() #Required coz sfdc uses jquery.ajax
      ), (data) ->
         alert "Query Error"
)

.controller('ContactViewCtrl', ($scope, AngularForce, $location, $routeParams, Contact) ->
   AngularForce.login ->
      Contact.get
         id: $routeParams.contactId
      , (contact) ->
         self.original = contact
         $scope.contact = new Contact(self.original)
         $scope.$apply() #Required coz sfdc uses jquery.ajax
)

.controller('ContactDetailCtrl', ($scope, AngularForce, $location, $routeParams, Contact) ->
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
)
