# Services

angular.module('skewer.services', [])

.factory("contentAssetsService", ['$http', '$q', '$timeout',
($http, $q, $timeout) ->
    # type will be something like 'text', 'image', etc...
    getContentItemsForType: (type) ->
        deferred = $q.defer()

        # fake a service call
        $timeout deferred.resolve.bind(deferred,
            a000: "Fake #{type} item 1"
            a001: "Fake #{type} item 2"
            a002: "Fake #{type} item 3"
            a003: "Fake #{type} item 4"
            a004: "Fake #{type} item 5"
            a005: "Fake #{type} item 6"
            a006: "Fake #{type} item 7"
            a007: "Fake #{type} item 8"
            a008: "Fake #{type} item 9"
            a009: "Fake #{type} item 10"
        ), 3000

        deferred.promise
])
