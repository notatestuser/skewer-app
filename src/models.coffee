angular.module('ForceModels', [])

.factory('Contact', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'Contact'
      fields: ['FirstName', 'LastName', 'Title', 'Phone', 'Email', 'Id', 'Account.Name']
      where: ''
      orderBy: 'LastName'
      limit: 20
   AngularForceObjectFactory(objDesc)
])

.factory('Opportunity', ['AngularForceObjectFactory', 'SFConfig',
(AngularForceObjectFactory, SFConfig) -> ->
   objDesc =
      type: 'Opportunity'
      fields: ['Id', 'Name', 'OwnerId', 'StageName','CreatedDate','Owner.Name','Probability']
      where: 'skewerapp__Show_In_Skewer__c = 1'
      orderBy: 'Probability DESC'
      limit: 20
   AngularForceObjectFactory(objDesc)
])

.factory('Pitch', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'skewerapp__Pitch__c'
      fields: [
         'Id',
         'skewerapp__Pitch_Link__c', # what is this?
         'skewerapp__roomId__c',
         'skewerapp__opportunityId__c',
         'skewerapp__fileList__c',
         'skewerapp__userId__c']
      where: ''
      orderBy: 'Name'
      limit: 10
   AngularForceObjectFactory(objDesc)
])

.factory('Assets', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   (type='image') ->
      objDesc =
         type: 'skewerapp__Pitch_Asset__c'
         fields: [
            'Id',
            'Name',
            'skewerapp__Source__c',
            'skewerapp__Tracked_Link__c',
            'skewerapp__Text__c']
         where: "skewerapp__Type__c = '#{type}' and skewerapp__Show_In_Skewer__c = 1"
         orderBy: 'Name'
         limit: 15
      AngularForceObjectFactory(objDesc)
])

.factory('Setting', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'skewerapp__Pitch_Settings__c'
      fields: [
         'Id',
         'skewerapp__Logo_Bar_Background_Colour__c', # what is this?
         'skewerapp__Page_Background_Colour__c',
         'skewerapp__Text_Colour__c',
         'skewerapp__Logo_Link__c']
      where: ''
      orderBy: 'Name'
      limit: 1
   AngularForceObjectFactory(objDesc)
])
