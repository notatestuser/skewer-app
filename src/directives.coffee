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
   link: ($scope, elem) ->
      elem.css backgroundImage: "url(#{$scope.component.content})"
])

.directive('pitchEditor', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      setRatioFn = ->
         width  = elem.outerWidth()
         height = elem.outerHeight()
         newRatio = (height / width).toFixed 3
         existingRatio = $scope.editorContext.aspectRatio
         elem.data aspectRatio: newRatio
         if $scope.editorContext.inEditMode
            $scope.editorContext.aspectRatio = newRatio
            elem.height null
         else
            elem.height width * existingRatio
         $scope.$apply()
      # on resize figure out what our aspect ratio is
      $(window).resize setRatioFn
      setRatioFn()
])
