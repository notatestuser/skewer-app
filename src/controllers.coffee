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
   'contactCompanyName'
   'salesforceOrgSiteHost'
]

window.app

.controller('HomeCtrl', ($scope, AngularForce, $location, $route) ->
   isOnline = AngularForce.isOnline()
   isAuthenticated = AngularForce.authenticated()
   
   if AngularForce.inCordova
      return $location.path "/contacts/"


   #Offline support (only for Cordova)
   #First check if we are online, then check if we are already authenticated (usually happens in Cordova),
   #If Both online and authenticated(Cordova), go directly to /contacts view. Else show login page.
   unless isOnline
      unless isAuthenticated #MobileWeb
         return $location.path "/login"
      else #Cordova
         return $location.path "/contacts/"


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

.controller('SkewerListCtrl', ($routeParams, $scope, AngularForce, $location, GoInstantRoomId, sfSkewersForOpportunity) ->
   return $location.path("/home")  unless AngularForce.authenticated()

   $scope.giRoomId = GoInstantRoomId.getRoomId()
   $scope.opportunityId = $routeParams.opportunityId
   $scope.skewers = sfSkewersForOpportunity
   $scope.searchTerm = ""

   $scope.showLoadingState = ->
      $scope.isLoading = true

   $scope.doSearch = ->
      Opportunity().search $scope.searchTerm, ((data) ->
         $scope.opportunities = data
         $scope.$apply() #Required coz sfdc uses jquery.ajax
      ), (data) ->
)

.controller('OpportunityListCtrl', ($scope, AngularForce, $location, GoInstantRoomId, sfOpportunities, Opportunity) ->
   return $location.path("/home")  unless AngularForce.authenticated()

   $scope.giRoomId = GoInstantRoomId.getRoomId()
   $scope.opportunities = sfOpportunities
   $scope.searchTerm = ""

   $scope.selectOpportunity = (opportunity) ->
      $scope.isLoading = opportunity.isLoading = true

   $scope.doSearch = ->
      Opportunity().search $scope.searchTerm, ((data) ->
         $scope.opportunities = data
         $scope.$apply() #Required coz sfdc uses jquery.ajax
      ), (data) ->
)

.controller('SkewerCanvasCtrl', ($routeParams, $location, $timeout, $rootScope, $scope, AngularForce, GoAngular, pitchesService, shareService, pageBrandingData, salesforceOpportunity, userContactDetails) ->
   return $location.path('/contacts') if not $routeParams?.opportunityId or not $routeParams?.roomId

   [opportunityId, pitchId, roomId] = [$routeParams?.opportunityId, $routeParams?.pitchId, $routeParams?.roomId]

   # so apparently GoInstant wasn't syncing these when they were in a hash, so I moved 'em out
   $scope.inEditMode = AngularForce.authenticated()
   $scope.salesforceOrgSiteHost = $scope.salesforceOrgSiteHost
   $scope.saveInProgress = no
   $scope.aspectRatio = 1.777 # mobile-esque default
   $scope.branding = '{}'

   # the pitchId is only available when in "view mode"
   $scope.pitchId = pitchId

   # grab the author's contact info (email, phone) for storing in the scope
   $scope.contactName  = userContactDetails?.name  or ''
   $scope.contactEmail = userContactDetails?.email or ''
   $scope.contactPhone = userContactDetails?.phone or ''
   $scope.contactCompanyName = salesforceOpportunity?.getskewer__Company_Name__c or ''

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

   $scope.composeTweet = ->
      return '' if not shareUrl = $scope.shareUrl
      window.plugins.twitter.composeTweet (s) ->
         console.log("tweet success")
      , (e) ->
         console.log("tweet failure: " + e)
      , "Text, URL", urlAttach: shareUrl

   $scope.composeEmail = ->
      return '' if not shareUrl = $scope.shareUrl
      window.plugins.emailComposer.show 
            to: 'to@example.com',
            cc: 'cc@example.com',
            bcc: 'bcc@example.com',
            subject: 'Example email message',
            body: '<h1>Hello, world!</h1>',
            isHtml: true,
            attachments: [
               # attach a HTML file using a UTF-8 encoded string
               {
                  mimeType: 'text/html',
                  encoding: 'UTF-8',
                  data: '<html><body><h1>Hello, World!</h1></body></html>',
                  name: 'demo.html'
               },
               # // attach a base-64 encoding of http://incubator.apache.org/cordova/images/cordova_128.png
               {
                  mimeType: 'image/png',
                  encoding: 'Base64',
                  data: 'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAACXBIWXMAAAsTAAALEwEAmpwYAAAB1WlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS4xLjIiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOkNvbXByZXNzaW9uPjE8L3RpZmY6Q29tcHJlc3Npb24+CiAgICAgICAgIDx0aWZmOlBob3RvbWV0cmljSW50ZXJwcmV0YXRpb24+MjwvdGlmZjpQaG90b21ldHJpY0ludGVycHJldGF0aW9uPgogICAgICAgICA8dGlmZjpPcmllbnRhdGlvbj4xPC90aWZmOk9yaWVudGF0aW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4K5JKPKQAAAtpJREFUOBFNU0toE1EUPTOZTJI2qbG0qUnwg1IFtSBI967cCBHcSsGFgktdC125EvwVLKi0FApaCChuRMSFqAitCNrGJE1DadpSYz5OvpPJ5Od5007xwc1998475513743U6/Uk7K1Op6O0Wq2pdrvt597odrugh/A0hcdk+luhUKhgY0Ryf5HsmizLNz0eN9qtNvRGA8xBdTohyxJjQ8TrBEzaIOk/BQNk3+YHL1WAKiyguL1Wr1tK3C6XteeZ01SRFCSy+Nlb07zdG0umcPvOXTyde8lbZbjcbjyYnsG5CxG8fvsBBJKs+8wG2QouMvFOJB9Mz+JnLA6P24UBnxcNo4nk2jpiiVWEQ2G8j87ApSqo643rgUBg1lJgGMaUAK/EkyhVaxg7eQLhoUEoThX9JBk54MVh/wDSm1uYj75Bv9eHRqNxL5PJTFpF1DRN8fX3oVKp4GhwGB6/H50eoO3sIBgYRpdvr/v8cCeS8KgOFHNZZLNZlfVTLQWKoixDkuElyeLXJdT7vGiHw/j+7QdezC9gCw6MX76Ezx+/QJYkVKiShU6y0MuWAjKlzJYJp+JAIZdDJl+AT3ZgM7OJYqGA4Jkx/C5X4XEpvMSDaq0K0zRTAmcRkCnZZutEm4p6A3MPn8Ahel/SoJstbEVf4dNCFIPBQ/ByRqpU0Gw2UyzbhkVAOSkywuGQMT5+HgOsuEtRIJ06jl63B4nqmuzGwZEAnE7FIhCYSCRSsggIXmcnxLtw4+oViNluc4Q7HCbbi4ES34tayRoyHknTdgdpdHQ0S4KcUJBKrdXuP3q8XGZH/uTzyOXyKJXLeD4zF1uJr2ZFnfh26Lq+sU8gSZJaLpfTBmWyQLWlxaWczlpoWskk2GzyefH4r7+JRGKHZ4WS9MTEREUQWJPIpJv7Y7SztCM0EYvV3XX7I28w3qbFaBtUotsEKhN+2hCtjybmwwZzay07pzMSf+cSCcx/K8WXLZEV/swAAAAASUVORK5CYII=',
                  name: 'cordova.png'
               },
               #// attach a file using a hypothetical file path
               #//,{ filePath: './path/to/your-file.jpg' }
            ],
            onSuccess: (winParam) ->
               console.log('EmailComposer onSuccess - return code ' + winParam.toString());
            ,
            onError: (error) ->
               console.log('EmailComposer onError - ' + error.toString());
)
