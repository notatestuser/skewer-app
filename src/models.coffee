angular.module('ForceModels', [])

.factory('Contact', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'Contact'
      fields: ['FirstName', 'LastName', 'Title', 'Phone', 'Email', 'Id', 'Account.Name']
      where: ''
      orderBy: 'LastName'
      limit: 20

   Contact = AngularForceObjectFactory(objDesc)
   Contact
])

.factory('Opportunity', ['AngularForceObjectFactory', 'SFConfig',
(AngularForceObjectFactory, SFConfig) -> ->
   objDesc =
      type: 'Opportunity'
      fields: ['Id', 'Name', 'OwnerId', 'CreatedDate']
      where: "OwnerId = '#{SFConfig.client.userId}'"
      orderBy: 'CreatedDate DESC'
      limit: 20

   Opportunity = AngularForceObjectFactory(objDesc)
   Opportunity
])

.factory('skewerapp__Pitch__c', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'skewerapp__Pitch__c'
      fields: ['Id', 'Name', 'skewerapp__Pitch_Link__c']
      where: ''
      orderBy: 'Name'
      limit: 10

   skewerapp__Pitch__c = AngularForceObjectFactory(objDesc)
   skewerapp__Pitch__c
])

.factory('Assets', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   (type='image') ->
      objDesc =
         type: 'skewerapp__Pitch_Asset__c'
         fields: ['Id', 'Name', 'skewerapp__Source__c', 'skewerapp__Tracked_Link__c', 'skewerapp__Text__c']
         where: "skewerapp__Type__c = '#{type}'"
         orderBy: 'Name'
         limit: 15

      ImageAsset = AngularForceObjectFactory(objDesc)
      ImageAsset
])
