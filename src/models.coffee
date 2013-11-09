angular.module('SFModels', [])

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

.factory('Opportunity', ['AngularForceObjectFactory',
(AngularForceObjectFactory) ->
   objDesc =
      type: 'Opportunity'
      fields: ['Name', 'CloseDate', 'Id']
      where: 'WHERE IsWon = TRUE'
      limit: 20

   Opportunity = AngularForceObjectFactory(objDesc)
   Opportunity
])
