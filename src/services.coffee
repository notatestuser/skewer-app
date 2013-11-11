# Services

angular.module('skewer.services', [])

.factory("contentAssetsService", ['$http', '$q', '$timeout',
($http, $q, $timeout) ->
    # type will be something like 'text', 'image', etc...
    getContentItemsForType: (type) ->
        deferred = $q.defer()

        # fake a service call
        $timeout deferred.resolve.bind(deferred,
            [1..10].reduce (prev, current, index) ->
                prev["a00#{index}"] = "Defunct #{type} item #{current}"
                prev
            , {}
        ), 3000

        deferred.promise
])
