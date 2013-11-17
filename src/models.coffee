angular.module('ForceModels', [])

.factory('Opportunity', ['AngularForceObjectFactory', 'SFConfig',
(AngularForceObjectFactory, SFConfig) -> ->
   objDesc =
      type: 'Opportunity'
      fields: [
         'Id',
         'Name',
         'OwnerId',
         'StageName',
         'CreatedDate',
         'Owner.Name',
         'Probability'
         'getskewer__Skewer_Site_URL__c']
      where: 'getskewer__Show_In_Skewer__c = 1'
      orderBy: 'Probability DESC'
      limit: 30
   AngularForceObjectFactory(objDesc)
])

.factory('Skewer', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   (byUserId, byOpportunityId) ->
      where  = "getskewer__Created_By_ID__c = '#{byUserId}'" if byUserId
      where += "and getskewer__Opportunity__c = '#{byOpportunityId}'" if byOpportunityId
      objDesc =
         type: 'getskewer__Skewer__c'
         fields: [
            'Id',
            'Name',
            'CreatedDate',
            'getskewer__Short_URL__c'
            'getskewer__Opportunity__c'
            'getskewer__Room_ID__c'
            'getskewer__File_List__c'
            'getskewer__Created_By_ID__c'
            'getskewer__Created_By_Name__c']
         where: where or ''
         orderBy: 'CreatedDate DESC'
         limit: 30
      AngularForceObjectFactory(objDesc)
])

.factory('Assets', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   (type='image') ->
      objDesc =
         type: 'getskewer__Skewer_Asset__c'
         fields: [
            'Id',
            'Name',
            'getskewer__Source__c',
            'getskewer__Tracked_Link__c',
            'getskewer__Text__c']
         where: "getskewer__Type__c = '#{type}' and getskewer__Show_In_Skewer__c = 1"
         orderBy: 'Name'
         limit: 15
      AngularForceObjectFactory(objDesc)
])

.factory('Setting', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'getskewer__Skewer_Settings__c'
      fields: [
         'Id',
         'getskewer__Logo_Bar_Background_Colour__c', # what is this?
         'getskewer__Page_Background_Colour__c',
         'getskewer__Text_Colour__c',
         'getskewer__Logo_Link__c']
      where: ''
      orderBy: 'Name'
      limit: 1
   AngularForceObjectFactory(objDesc)
])

.factory('User', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'User',
      fields: [
         'Id',
         'getskewer__Skewer_Name__c',
         'getskewer__Skewer_Email__c',
         'getskewer__Skewer_Phone__c']
      where: 'getskewer__User_Is_Me__c = 1'
      orderBy: ''
      limit: 1
   AngularForceObjectFactory(objDesc)
])
