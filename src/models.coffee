angular.module('ForceModels', [])

.factory('Contact', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'Contact'
      fields: [
         'FirstName',
         'LastName',
         'Title',
         'Phone',
         'Email',
         'Id',
         'Account.Name']
      where: ''
      orderBy: 'LastName'
      limit: 20
   AngularForceObjectFactory(objDesc)
])

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
         'Probability']
      where: 'getskewer__Show_In_Skewer__c = 1'
      orderBy: 'Probability DESC'
      limit: 20
   AngularForceObjectFactory(objDesc)
])

.factory('Pitch', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'getskewer__Skewer__c'
      fields: [
         'Id',
         'getskewer__Skewer_Link__c', # what is this?
         'getskewer__roomId__c',
         'getskewer__opportunityId__c',
         'getskewer__fileList__c',
         'getskewer__userId__c']
      where: ''
      orderBy: 'Name'
      limit: 10
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
            'Email',
            'Phone']
         where: 'User_Is_Me__c = 1'
         orderBy: ''
         limit: 1
      AngularForceObjectFactory(objDesc)
   ])
