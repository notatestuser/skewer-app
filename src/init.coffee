###
This initializes AngularJS app. Place this file BEFORE app.js (where your actual app is located).
###

#var app = angular.module('AngularSFDemo', ['AngularForce', 'AngularForceObjectFactory', 'Contact', 'ui.bootstrap.dropdownToggle']);
#app.constant('SFConfig', getSFConfig());
initApp = (options, forcetkClient) ->
   options = options or {}
   options.loginUrl = SFConfig.sfLoginURL
   options.clientId = SFConfig.consumerKey
   options.apiVersion = "v27.0"
   options.userAgent = "SalesforceMobileUI/alpha"
   options.proxyUrl = options.proxyUrl or SFConfig.proxyUrl

   #In VF, you should get sessionId and use that as accessToken while initializing forcetk(Force.init)
   options.accessToken = SFConfig.sessionId  if SFConfig.sessionId

   #Init force
   Force.init options, options.apiVersion, forcetkClient

   # SFConfig.client = Force.forcetkClient;

   #sforce.connection.init(options.accessToken, options.instanceUrl + '/services/Soap/u/' + options.apiVersion, options.useProxy);
   if navigator.smartstore
      SFConfig.dataStore = new Force.StoreCache("sobjects", [
         path: "Name"
         type: "string"
      ,
         path: "attributes.type"
         type: "string"
      ], "Id")
      SFConfig.dataStore.init()

#mockStore.useSessionStorage();

#Uncomment below and set accessToken(= sessionId), instanceUrl and proxyUrl to test smartstore (mock version - coz real smartstore is part of cordova)
# inside the browser
#initApp({
#    accessToken: '00Di0000000JEm3!AQ4AQLnaKs7PPHaRd0xjvJwJkf6O.9R7ECpU5mndDb1DwYsoxhMDrCyEag.5Ws_HFI5fY.9fYgsQ_4F1D5vXltKmK5b7guCK',
#    instanceUrl: 'https://na15.salesforce.com',
#    proxyUrl: 'http://localhost:3000/proxy/'
#});

###
Configure all the AngularJS routes here.
###

###
Please configure Salesforce consumerkey, proxyUrl etc in getSFConfig().

SFConfig is a central configuration JS Object. It is used by angular-force.js and also your app to set and retrieve
various configuration or authentication related information.

Note: Please configure SFConfig Salesforce consumerkey, proxyUrl etc in getSFConfig() below.

@property SFConfig Salesforce Config object with the following properties.
@attribute {String} sfLoginURL       Salesforce login url
@attribute {String} consumerKey      Salesforce app's consumer key
@attribute {String} oAuthCallbackURL OAuth Callback URL. Note: If you are running on Heroku or elsewhere you need to set this.
@attribute {String} proxyUrl         URL to proxy cross-domain calls. Note: This nodejs app acts as a proxy server as well at <location>/proxy/
@attribute {String} client           ForcetkClient. Set by forcetk lib
@attribute {String} sessionId        Session Id. Set by forcetk lib
@attribute {String} apiVersion       REST Api version. Set by forcetk (Set this manually for visualforce)
@attribute {String} instanceUrl      Your Org. specific url. Set by forcetk.

@returns SFConfig object depending on where (localhost v/s heroku v/s visualforce) the app is running.
###

getSFConfig = ->
   location = document.location
   href = location.href
   if href.indexOf("file:") >= 0 #Phonegap
      {}
   else if configFromEnv and configFromEnv.sessionId #VisualForce just sets sessionId (as that's all what is required)
      sessionId: configFromEnv.sessionId
   else
      throw "Environment variable client_id and/or app_url is missing. Please set them before you start the app"  if not configFromEnv or configFromEnv.client_id is "" or configFromEnv.client_id is "undefined" or configFromEnv.app_url is "" or configFromEnv.app_url is "undefined"
      sfLoginURL: "https://login.salesforce.com/"
      consumerKey: configFromEnv.client_id
      oAuthCallbackURL: removeTrailingSlash(configFromEnv.app_url) + "/#/callback"
      proxyUrl: removeTrailingSlash(configFromEnv.app_url) + "/proxy/"

#Helper
removeTrailingSlash = (url) ->
   url.replace /\/$/, ""
