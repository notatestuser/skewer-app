window.app

.directive('baseComponent', ['$compile', ($compile) ->
   restrict: 'AC'
   # compile: (elem, attrs) ->
   #    elem.addClass "#{attrs.type}-component"
   #    elem
   link: ($scope, elem, attrs) ->
      return unless typeof (component = $scope.component) is 'object'
])

.directive('imageComponentBody', [->
   restrict: 'AC'
   link: (scope, elem) ->
      elem.css backgroundImage: "url(#{scope.component.content})"
])

.directive('pitchEditor', [->
   restrict: 'AC'
   link: (scope, elem) ->
      setRatioFn = ->
         width  = elem.outerWidth()
         height = elem.outerHeight()
         newRatio = height / width
         elem.data 'ratio', newRatio
         console.log newRatio
      $(window).resize setRatioFn
])
