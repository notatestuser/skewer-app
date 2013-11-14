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
            console.log "Our instanceUrl is #{SFConfig.client.instanceUrl}"
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

.controller('PitchShareCtrl', ($location, $scope, shareShortUrl) ->
   return $location.path('/') if not shareUrl = shareShortUrl?.data?.url
   $scope.shareUrl = shareUrl

   $scope.getTwitterTweetButtonSrc = ->
      "//platform.twitter.com"+
      "/widgets/tweet_button.1384205748.html"+
      "#count=none"+
      "&id=twitter-widget-0"+
      "&lang=en"+
      "&size=l"+
      "&text="+encodeURIComponent("Here's some follow-up information you might find useful")+
      "&url=#{encodeURIComponent(shareUrl)}&via=SkewerApp"
)

.controller('PitchEditorCtrl', ($window, $routeParams, $location, $scope, AngularForce, GoAngular, SFConfig) ->
   return $location.path('/contacts') if not $routeParams?.opportunityId or not $routeParams?.roomId

   # GoInstant alternative platform init
   # connectUrl = 'https://goinstant.net/sdavyson/Skewer'
   # rooms = ['room101']
   # platform.setup(connectUrl, { rooms: rooms })

   # so apparently GoInstant wasn't syncing these when they were in a hash, so I moved 'em out
   $scope.inEditMode  = AngularForce.authenticated()
   $scope.aspectRatio = 1.777 # mobile-esque default
   $scope.saveInProgress = no

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

   compactComponents = ->
      $scope.components = $scope.components.filter (item) -> item?
      undefined

   $scope.addComponentAfter = (index = $scope.components.length - 1) ->
      newComponents = [
         # use the same scale as the component at the given index
         rowScale:  if index > -1 then $scope.components[index].rowScale  else 1
         colDivide: if index > -1 then $scope.components[index].colDivide else 1
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

   $scope.shouldShowSaveButton = ->
      $scope.saveInProgress or $scope.inEditMode

   $scope.save = ->
      $scope.inEditMode = no
      data = p:
         roomId: roomId = $routeParams.roomId
         opportunityId: opportunityId = $routeParams?.opportunityId
         fileList: _.pluck($scope.components, 'id').toString()
         userId: SFConfig.client.userId
      paramMap =
         'SalesforceProxy-Endpoint': 'https://pitch-developer-edition.na15.force.com/services/apexrest/PitchCreate'
      callbackFn = (data) ->
         # alert JSON.stringify data
         $location.path "/skewer/#{opportunityId}/#{roomId}/share"

      $scope.saveInProgress = yes

      # ⚑
      # TODO: This is broken for now
      # SFConfig.client.apexrest('/PitchCreate', callbackFn, null, 'PUT', JSON.stringify(data), paramMap)
      callbackFn()

   # when EditMode is off we should sync with GoInstant
   $scope.$watch 'inEditMode', inEditModeWatchFn = (newValue, oldValue) ->
      return if newValue is oldValue or newValue
      # GoAngular initialisation when not in edit mode
      new GoAngular(
            $scope,
            'PitchEditorCtrl',
            include: ['inEditMode', 'aspectRatio', 'components', 'pitch']
            room: $routeParams.roomId)
         .initialize()

   inEditModeWatchFn(false) if not $scope.inEditMode
)

.controller('OpportunityListCtrl', ($scope, AngularForce, $location, GoInstantRoomId, Opportunity, SFConfig) ->
   return $location.path("/home")  unless AngularForce.authenticated()
   $scope.giRoomId = GoInstantRoomId.getRoomId()
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

)


