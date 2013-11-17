###
Describe Salesforce object to be used in the app. For example: Below AngularJS factory shows how to describe and
create an 'Contact' object. And then set its type, fields, where-clause etc.

PS: This module is injected into ListCtrl, EditCtrl etc. controllers to further consume the object.
###

GOINSTANT_CANVAS_SCOPE_SYNC_INCLUDES = [
   'aspectRatio'
   'inEditMode'
   'components'
   'branding'
   'contactName'
   'contactEmail'
   'contactPhone'
   'salesforceOrgSiteHost'
]

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

.controller('OpportunityListCtrl',
($scope, AngularForce, $location, GoInstantRoomId, sfOpportunities, Opportunity, SFConfig) ->
   return $location.path("/home")  unless AngularForce.authenticated()
   $scope.giRoomId = GoInstantRoomId.getRoomId()
   $scope.searchTerm = ""
   $scope.working = false
   $scope.opportunities = sfOpportunities

   $scope.isWorking = ->
      $scope.working

   $scope.doSearch = ->
      Opportunity().search $scope.searchTerm, ((data) ->
         $scope.opportunities = data
         $scope.$apply() #Required coz sfdc uses jquery.ajax
      ), (data) ->
)

.controller('SkewerCanvasCtrl', ($routeParams, $location, $timeout, $rootScope, $scope, AngularForce, GoAngular, pitchesService, shareService, pageBrandingData, salesforceOrgSiteHost, userContactDetails) ->
   return $location.path('/contacts') if not $routeParams?.opportunityId or not $routeParams?.roomId

   [opportunityId, pitchId, roomId] = [$routeParams?.opportunityId, $routeParams?.pitchId, $routeParams?.roomId]

   # so apparently GoInstant wasn't syncing these when they were in a hash, so I moved 'em out
   $scope.inEditMode = AngularForce.authenticated()
   $scope.salesforceOrgSiteHost = salesforceOrgSiteHost
   $scope.saveInProgress = no
   $scope.aspectRatio = 1.777 # mobile-esque default
   $scope.branding = '{}'

   # the pitchId is only available when in "view mode"
   $scope.pitchId = pitchId

   # grab the author's contact info (email, phone) for storing in the scope
   $scope.contactName  = userContactDetails?.name  or ''
   $scope.contactEmail = userContactDetails?.email or ''
   $scope.contactPhone = userContactDetails?.phone or ''

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
   unless $scope.inEditMode
      $scope.components = [
         rowScale:  2
         colDivide: 1
         type: 'loading'
      ]
   else
      $scope.components = [
         rowScale:  2
         colDivide: 2
         type: 'text'
         renderUnsafeHtml: true
         content: "Let's get started.<br>Just tap on the placeholder to the right of this message to place your first chunk."
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
      applyOrgBranding()
      $rootScope.$broadcast 'component:editme', newComponents[0], true

   $scope.removeComponentAt = (index=-1) ->
      return if not $scope.components[index]
      delete $scope.components[index]
      compactComponents()

   $scope.shouldShowSaveButton = ->
      $scope.saveInProgress or ($scope.inEditMode and $scope.components?.length)

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
            'SkewerEditorCtrl',
            include: GOINSTANT_CANVAS_SCOPE_SYNC_INCLUDES
            room: $routeParams.roomId)
         .initialize()
         .then ->
            # take us to the "share" page!
            if Boolean oldValue
               # ... and just to be sure we've synced...
               $timeout ->
                  shareService.storeAttributesAndGoToSharePage roomId, opportunityId, $scope.components
               , 1000
         , (err) ->
            console.error 'GoInstant initialization error', err
            alert "Couldn't sync with GoInstant :("

   # fetch and configure page branding colours & logo in edit mode
   applyOrgBranding = ->
      return if not brandingData = pageBrandingData
      $scope.branding = JSON.stringify brandingData

   # when branding is updated on the scope, by GI or otherwise, we'll have to apply it
   $scope.$watch 'branding', (newValue) ->
      return if not newValue or not _.isString(newValue)
      $scope.$emit 'branding:apply', JSON.parse(newValue)
      $scope.$emit 'branding:hidechrome' if not $scope.inEditMode
   , true

   # if the user changes `inEditMode` we know it's high time for some syncin'
   $scope.$watch 'inEditMode', inEditModeWatchCallbackFn

   if $scope.inEditMode
      # we need to apply corpo branding here
      applyOrgBranding()
   else
      # when "edit mode" is off on load we should sync with GoInstant but not redirect
      inEditModeWatchCallbackFn(false)
      # when GoInstant has synced we should track a page view
      $scope.$watch 'salesforceOrgSiteHost', (newValue, oldValue) ->
         return if newValue is oldValue
         pitchesService.trackPageViewInSalesforce newValue, roomId, opportunityId, pitchId
)

.controller('SkewerShareCtrl', ($location, $scope, shareService, urlShortenerService, pitchesService, salesforcePitchId) ->
   [roomId, fileIdList, opportunityId] = [
      shareService.get('roomId'),
      shareService.get('fileIdList'),
      shareService.get('opportunityId')
   ]

   urlShortenerService.generateShortUrlToSkewer(roomId, opportunityId, salesforcePitchId)
   .then (url) ->
      _shareUrl = $scope.shareUrl = url?.data?.url
      # update the URL in salesforce (this can & will happen in the background)
      pitchesService.updatePitchShortUrlInSalesforce $scope.salesforceOrgSiteHost, salesforcePitchId, _shareUrl

   $scope.getMailtoLink = ->
      return '' if not shareUrl = $scope.shareUrl
      "mailto:"+
      "?X-Sent-Via=Skewer"+
      "&subject="+encodeURIComponent('Following up on our meeting')+
      "&body=#{encodeURIComponent('Please check this information I have put together for you. '+shareUrl)}"

   $scope.getTwitterTweetButtonLink = ->
      return '' if not shareUrl = $scope.shareUrl
      "https://twitter.com/intent/tweet"+
      "?original_referer=https%3A%2F%2Fapp.getskewer.com%2F"+
      "&text="+encodeURIComponent("Here's some follow-up information that I think you'll find useful")+
      "&url=#{encodeURIComponent(shareUrl)}"+
      "&tw_p=tweetbutton"+
      "&via=SkewerApp"
)
