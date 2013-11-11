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

.factory('Pitch__c', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'Pitch__c'
      fields: ['Id', 'Name', 'Pitch_Link__c']
      where: ''
      orderBy: 'Name'
      limit: 10

   Pitch__c = AngularForceObjectFactory(objDesc)
   Pitch__c
])

.factory('Assets', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   (type='image') ->
      objDesc =
         type: 'Pitch_Asset__c'
         fields: ['Id', 'Name', 'Link__c']
         where: "Type__c = '#{type}'"
         orderBy: 'Name'
         limit: 10

      ImageAsset = AngularForceObjectFactory(objDesc)
      ImageAsset
])
