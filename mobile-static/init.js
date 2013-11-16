 var forcetkClient;
    var debugMode = true;
    var logToConsole = cordova.require("salesforce/util/logger").logToConsole;

    jQuery(document).ready(function() {
        //Add event listeners and so forth here
        logToConsole("onLoad: jquery ready");
		document.addEventListener("deviceready", onDeviceReady,false);

    });

    // When this function is called, Cordova has been initialized and is ready to roll 
    function onDeviceReady() {
        logToConsole("onDeviceReady: Cordova ready");
		//Call getAuthCredentials to get the initial session credentials
        cordova.require("salesforce/plugin/oauth").getAuthCredentials(salesforceSessionRefreshed, getAuthCredentialsError);

        //register to receive notifications when autoRefreshOnForeground refreshes the sfdc session
        document.addEventListener("salesforceSessionRefresh",salesforceSessionRefreshed,false);

        //enable buttons
        regLinkClickHandlers();
    }
        

    function salesforceSessionRefreshed(creds) {
        logToConsole("salesforceSessionRefreshed");
        
        // Depending on how we come into this method, `creds` may be callback data from the auth
        // plugin, or an event fired from the plugin.  The data is different between the two.
        var credsData = creds;
        if (creds.data)  // Event sets the `data` object with the auth data.
            credsData = creds.data;

        forcetkClient = new forcetk.Client(credsData.clientId, credsData.loginUrl, null,
            cordova.require("salesforce/plugin/oauth").forcetkRefresh);
        forcetkClient.setSessionToken(credsData.accessToken, apiVersion, credsData.instanceUrl);
        forcetkClient.setRefreshToken(credsData.refreshToken);
        forcetkClient.setUserAgentString(credsData.userAgent);
    }

    function getAuthCredentialsError(error) {
        logToConsole("getAuthCredentialsError: " + error);
    }