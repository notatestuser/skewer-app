window.app

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
         $scope.$apply() if $scope.$$phase isnt '$digest'
      # on resize figure out what our aspect ratio is
      $(window).resize _.debounce(setRatioFn, 200)
      setRatioFn()
])

.directive('baseComponent', ['$compile', ($compile) ->
   restrict: 'AC'
   removeRowScaleClassesFn = (elem) ->
      for scale in [1..10]
         elem.removeClass "row-scale-#{scale}"
   {
      restrict: 'AC'
      link: ($scope, elem) ->
         component = $scope.component
         return if not _.isObject(component)
         reconcileRowScaleClassFn = ->
            removeRowScaleClassesFn(elem)
            elem.addClass "row-scale-#{component.rowScale}"
         $scope.$watch 'component.rowScale', (newValue, oldValue) ->
            return unless newValue isnt oldValue
            reconcileRowScaleClassFn()
         reconcileRowScaleClassFn()
   }
])

.directive('componentBody', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      component = $scope.component
      return if not _.isObject(component)
      # ⚑
      # TODO: Write some code here!
])

.directive('imageComponentBody', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      elem.css backgroundImage: "url(#{$scope.component.content})"
])

.directive('componentEditModal', [->
   scope: {}
   restrict: 'A'
   templateUrl: '/partials/components/component-edit-modal.html'
   controller: ['$scope', ($scope) ->
      $scope.doAndClose = (fn) ->
         result = fn() if fn
         $scope.modalEl.modal 'hide' if result
      $scope.extendRow = ->
         condition = $scope.component.rowScale < 8
         $scope.component.rowScale++ if condition
         condition
      $scope.reduceRow = ->
         condition = $scope.component.rowScale > 1
         $scope.component.rowScale-- if condition
         condition
      $scope.setRowToDefault = ->
         condition = $scope.component.rowScale isnt 1
         $scope.component.rowScale = 1 if condition
         condition
   ]
   link: ($scope, elem) ->
      modalEl = $scope.modalEl = elem.children('.modal').first()
      $scope.$on 'component:editme', (ev, component) ->
         $scope.component = component
         modalEl.modal()
])
