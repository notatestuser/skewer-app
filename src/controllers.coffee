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

.controller('PitchShareCtrl', ($location, $scope, shareService, urlShortenerService, pitchesService, salesforcePitchId) ->
   [roomId, fileIdList, opportunityId] = [
      shareService.get('roomId'),
      shareService.get('fileIdList'),
      shareService.get('opportunityId')
   ]

   urlShortenerService.generateShortUrlToSkewer(roomId, opportunityId, salesforcePitchId)
   .then (url) ->
      _shareUrl = $scope.shareUrl = url?.data?.url
      # update the URL in salesforce (this can & will happen in the background)
      pitchesService.updatePitchShortUrlInSalesforce salesforcePitchId, _shareUrl

   $scope.getTwitterTweetButtonSrc = ->
      return '' if not shareUrl = $scope.shareUrl
      "//platform.twitter.com"+
      "/widgets/tweet_button.1384205748.html"+
      "#count=none"+
      "&id=twitter-widget-0"+
      "&lang=en"+
      "&size=l"+
      "&text="+encodeURIComponent("Here's some follow-up information you might find useful")+
      "&url=#{encodeURIComponent(shareUrl)}&via=SkewerApp"
)

.controller('PitchEditorCtrl', ($routeParams, $location, $timeout, $scope, AngularForce, GoAngular, pageBrandingService, pitchesService, shareService) ->
   return $location.path('/contacts') if not $routeParams?.opportunityId or not $routeParams?.roomId

   [opportunityId, pitchId, roomId] = [$routeParams?.opportunityId, $routeParams?.pitchId, $routeParams?.roomId]

   # so apparently GoInstant wasn't syncing these when they were in a hash, so I moved 'em out
   $scope.inEditMode  = AngularForce.authenticated()
   $scope.branding = '{}'
   $scope.aspectRatio = 1.777 # mobile-esque default
   $scope.saveInProgress = no

   # the pitchId is only available when in "view mode"
   $scope.pitchId = pitchId

   # initialise an array of page components
   #  | example component:
   #  |  {
   #  |     rowScale: 1
   #  |     colDivide: 1
   #  |     type: 'image'
   #  |     source: '... sf file id? ...'
   #  |     linkHref = 'http://getskewer.com/...'
   #  |  }
   # ⚑
   # TODO: Vary the content of this array based on whether the user is authenticated
   $scope.components = [
      rowScale:  2
      colDivide: 2
      type: 'image'
      content: 'http://i.imgur.com/wdt4Ddz.jpg'
   ]

   compactComponents = ->
      $scope.components = $scope.components.filter (item) -> item?

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
      fetchAndApplyOrgBranding()
      $scope.$broadcast 'component:editme', newComponents[0], true

   $scope.removeComponentAt = (index=-1) ->
      return if not $scope.components[index]
      delete $scope.components[index]
      compactComponents()

   $scope.shouldShowSaveButton = ->
      $scope.saveInProgress or $scope.inEditMode

   $scope.save = ->
      $scope.saveInProgress = yes
      $scope.pitchId    = pitchId
      $scope.inEditMode = no

   # this is the callback for the following $scope.$watch()
   inEditModeWatchCallbackFn = (newValue, oldValue) ->
      return if newValue is oldValue or newValue
      # GoAngular initialisation when not in edit mode
      new GoAngular(
            $scope,
            'PitchEditorCtrl',
            include: ['inEditMode', 'aspectRatio', 'components', 'branding']
            room: $routeParams.roomId)
         .initialize()
         .then ->
            # take us to the "share" page!
            if Boolean oldValue
               # ... and just to be sure we've synced...
               $timeout ->
                  shareService.storeAttributesAndGoToSharePage roomId, opportunityId, $scope.components
               , 300
         , (err) ->
            console.error 'GoInstant initialization error', err
            alert "Couldn't sync with GoInstant :("

   # fetch and configure page branding colours & logo in edit mode
   fetchAndApplyOrgBranding = ->
      pageBrandingService.fetchPageBrandingDescriptor (err, _brandingData) ->
         return if err
         $scope.$apply ->
            # this is caught by the appliesBranding directive
            $scope.branding = JSON.stringify _brandingData

   # when branding is updated on the scope, by GI or otherwise, we'll have to apply it
   $scope.$watch 'branding', (newValue) ->
      return if not newValue or not _.isString(newValue)
      $scope.$emit 'branding:apply', JSON.parse(newValue)
   , true

   # if the user changes `inEditMode` we know it's high time for some syncin'
   $scope.$watch 'inEditMode', inEditModeWatchCallbackFn

   if $scope.inEditMode
      # we need to apply corpo branding here
      fetchAndApplyOrgBranding()
   else
      # when "edit mode" is off on load we should sync with GoInstant but not redirect
      inEditModeWatchCallbackFn(false)
      # track a page view if not authed
      pitchesService.trackPageViewInSalesforce roomId, opportunityId, pitchId
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
