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

.directive('componentEditModal', ['contentAssetsService',
(contentAssetsService) ->
   scope: {}
   restrict: 'A'
   templateUrl: '/partials/components/component-edit-modal.html'
   controller: ['$scope', ($scope) ->
      $scope.doAndClose = (fn) ->
         result = fn() if fn
         $scope.modalEl.modal 'hide' if result or not fn
         # ⚑
         # TODO: Replace with scope fn that actually sets the content
         $scope.choosingContent = false
      $scope.doAndShowEditContentSlide = (fn) ->
         fn() if fn
         component = $scope.component
         if component.type and component.type isnt 'placeholder'
            $scope.choosingContent = true
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
      $scope.setContent = (content) -> ->
         $scope.component.content = content
         true
   ]
   link: ($scope, elem) ->
      modalEl = $scope.modalEl = elem.children('.modal').first()

      $scope.$on 'component:editme', (ev, component, isNewComponent) ->
         $scope.component = component
         $scope.choosingType = isNewComponent
         $scope.choosingContent = false
         modalEl.modal()

      $scope.$watch 'choosingContent', (newValue, oldValue) ->
         return if newValue is oldValue
         return $scope.availableContentItems = null if newValue isnt true
         Spinner = require('spinner')
         spinner = new Spinner
         spinner.size 30
         $('.loading-spinner-container', elem)
            .empty()
            .append spinner.el
         contentAssetsService.getContentItemsForType($scope.component.type)
         .then (items) ->
            $scope.availableContentItems = items
])
