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
   removeScaleClassesFn = (elem) ->
      for scale in [1..10]
         elem.removeClass "row-scale-#{scale} col-divide-#{scale}"
   {
      restrict: 'AC'
      link: ($scope, elem) ->
         component = $scope.component
         return if not _.isObject(component)
         reconcileRowScaleClassFn = ->
            removeScaleClassesFn(elem)
            elem.addClass "row-scale-#{component.rowScale} col-divide-#{component.colDivide}"
         $scope.$watch 'component.rowScale+component.colDivide', (newValue, oldValue) ->
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

.directive('placeholderComponentBody', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      newBackgroundImage = "url(http://lorempixel.com/1024/768/)"
      return if elem.css('background-image') is newBackgroundImage
      elem.css backgroundImage: newBackgroundImage
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
      $scope.splitColumn = ->
         condition = $scope.component.colDivide <= 1
         $scope.component.colDivide++ if condition
         condition
      $scope.mergeColumn = ->
         condition = $scope.component.colDivide >= 2
         $scope.component.colDivide-- if condition
         condition
      $scope.showChooseTypeList = ->
         $scope.choosingType = true
      $scope.setType = (contentType) -> ->
         $scope.component.type = contentType
         delete $scope.component.content if contentType isnt 'placeholder'
         true
   ]
   link: ($scope, elem) ->
      modalEl = $scope.modalEl = elem.children('.modal').first()
      $scope.$on 'component:editme', (ev, component, isNewComponent) ->
         $scope.component = component
         $scope.choosingType = isNewComponent
         modalEl.modal()
])
