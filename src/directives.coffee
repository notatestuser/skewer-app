COMPONENT_LINK_PID_PLACEHOLDER = '[PITCHID]'

window.app

.directive('pitchEditor', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      setRatioFn = ->
         return if not $scope.aspectRatio
         elem.css height: "#{$(window).outerHeight()}px"
         width  = elem.outerWidth()
         height = elem.outerHeight()
         newRatio = (height / width).toFixed 3
         existingRatio = $scope.aspectRatio
         elem.data aspectRatio: newRatio
         if $scope.inEditMode
            $scope.aspectRatio = newRatio
            elem.height null
         else
            elem.height width * existingRatio
         if $scope.$$phase isnt '$digest'
            $scope.$apply()
            console.trace "Phase is "+$scope.$$phase
      # on resize figure out what our aspect ratio is
      $(window).resize _.debounce(setRatioFn, 60)
      $scope.$watch 'aspectRatio', setRatioFn
      $scope.$watch 'inEditMode',  setRatioFn
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

.directive('componentBody', ['$window', '$rootScope',
($window, $rootScope) ->
   restrict: 'AC'
   controller: ($scope) ->
      $scope.getComponentClasses = (component={}) ->
         type = component.type or 'placeholder'
         baseClasses =  ''
         baseClasses += " #{type}-component"
         baseClasses
      $scope.handleComponentClick = (component={}) ->
         if $scope.inEditMode
            $rootScope.$broadcast 'component:editme', component
         else if component.linkHref
            # ⚑
            # TODO: Show a confirmation modal when we're here
            linkHref = component.linkHref.replace COMPONENT_LINK_PID_PLACEHOLDER, $scope.pitchId
            $window.location.href = linkHref
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
      $scope.$watch 'component.content', (newValue, oldValue) ->
         return if newValue is oldValue
         elem.css backgroundImage: "url(#{newValue})"
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
      $scope.setContentAndLinkHref = (id, content, linkHref) -> ->
         $scope.component.id = id
         $scope.component.content = content
         $scope.component.linkHref = linkHref
         $scope.$apply() if $scope.$$phase isnt '$digest'
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
         spinner.size 26
         $('.loading-spinner-container', elem)
            .empty()
            .append spinner.el
         contentAssetsService.getContentItemsForType $scope.component.type, (err, items) ->
            $scope.availableContentItems = items
            $scope.$apply() if $scope.$$phase isnt '$digest'
            undefined
])

.directive('tapToAddComponent', ['$timeout', ($timeout) ->
   restrict: 'A'
   link: ($scope, elem) ->
      elem.data 'rowScaleClass', 'row-scale-1'
      elem.click ->
         elem.addClass 'hover'
         # the animation should be done after 0.3s
         $timeout ->
            $scope.addComponentAfter()
            elem.removeClass 'hover'
         , 320
      $scope.$watch 'components', (newValue) ->
         return if not _.isArray(newValue) or newValue.length < 1
         # mimic row scale of last component
         lastComponent    = newValue[newValue.length - 1]
         newRowScaleClass = "row-scale-#{lastComponent.rowScale}"
         elem
            .removeClass(elem.data 'rowScaleClass')
            .addClass(newRowScaleClass)
         elem.data 'rowScaleClass', newRowScaleClass
      , true
])

.directive('appliesBranding', ['$rootScope', ($rootScope) ->
   link: ($scope, elem, attrs) ->
      $rootScope.$on 'branding:apply', (ev, _brandingData={}) ->
         return if not _.isObject(_brandingData) or _.isEmpty(_brandingData)
         _styles = switch attrs?.brandingType or 'page'
            when 'page'
               color: _brandingData.textColour
               backgroundColor: _brandingData.pageBgColour
            when 'top-bar'
               display: 'block'
               backgroundColor: _brandingData.barBgColour
            else {}
         _attrs = switch attrs?.brandingType or 'page'
            when 'top-bar-logo'
               src: _brandingData.logoSrcUrl
            else {}
         elem.attr _attrs
         elem.css  _styles
])

.directive('hidesWhenBrandingApplied', ['$rootScope', ($rootScope) ->
   link: ($scope, elem) ->
      $rootScope.$on 'branding:hidechrome', ->
         elem.addClass 'hide'
])

.directive('loadingSpinner', [ ->
   link: ($scope, elem, attrs) ->
      Spinner = require('spinner')
      spinner = new Spinner
      spinner.size parseInt(attrs.spinnerSize) if attrs?.spinnerSize
      elem
         .empty()
         .append spinner.el
])
