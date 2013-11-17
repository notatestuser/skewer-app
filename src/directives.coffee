COMPONENT_LINK_PID_PLACEHOLDER = '[PITCHID]'

window.app

.directive('appliesAdaptiveFontSizing', [->
   restrict: 'A'
   link: ($scope, elem, attrs={}) ->
      [minSize, maxSize]   = [attrs.minFontSize or 11, attrs.maxFontSize or 15]
      [minWidth, maxWidth] = [320, 768]
      sizeDelta  = maxSize - minSize
      minMaxDelta = maxWidth - minWidth
      sizePerPixel = sizeDelta / minMaxDelta
      setFontSizeFn = ->
         windowWidth = $(window).outerWidth()
         return if windowWidth < minWidth
         fontSize = minSize + (Math.min(windowWidth - minWidth, minMaxDelta) * sizePerPixel)
         elem.css fontSize: "#{fontSize}px"
      $(window).resize _.debounce(setFontSizeFn, 100)
      $(elem).resize   _.debounce(setFontSizeFn, 30)
      $scope.$on 'adaptive-font-size:recalc', setFontSizeFn
      setFontSizeFn()
])

.directive('pitchEditor', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      setRatioFn = ->
         return if not $scope.aspectRatio
         elem.css height: "#{$(window).outerHeight()-135}px"
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
      # on resize figure out what our aspect ratio is
      $(window).resize _.debounce(setRatioFn, 100)
      $scope.$watch 'aspectRatio', setRatioFn
      $scope.$watch 'inEditMode',  setRatioFn
      $scope.$watch 'components',  setRatioFn, yes
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
            $rootScope.$broadcast 'component:editme', component, no
         else if component.linkHref
            # ⚑
            # TODO: Show a confirmation modal when we're here
            linkHref = component.linkHref.replace COMPONENT_LINK_PID_PLACEHOLDER, $scope.pitchId
            $window.location.href = linkHref
   link: ($scope, elem) ->
      component = $scope.component
      return if not _.isObject(component)
      elem.click ->
         $scope.handleComponentClick component
])

.directive('textComponentBody', [->
   restrict: 'AC'
   link: ($scope, elem) ->
      isOverflowing = (el) ->
         el.clientHeight < el.scrollHeight
      fitOverflowingTextFn = ->
         el = elem[0]
         return $scope.$emit('adaptive-font-size:recalc') unless isOverflowing(el)
         while isOverflowing(el)
            currentFontSize = parseFloat(el.style?.fontSize or elem.css 'font-size')
            break if currentFontSize < 1 or not el.style
            el.style.fontSize = "#{currentFontSize-.1}px"
      $scope.$watch 'component.content', updateBodyFn = (newValue, oldValue) ->
         return if newValue is oldValue
         content = $scope.component.content
         if $scope.component?.renderUnsafeHtml
            elem.html content
         else
            elem.text content
         fitOverflowingTextFn()
      $scope.$watch 'component.rowScale', _.debounce(fitOverflowingTextFn, 300)
      $(window).resize _.debounce(fitOverflowingTextFn, 100)
      updateBodyFn true
      fitOverflowingTextFn()
])

.directive('imageComponentBody', [->
   sslizeImageSrc = (src='') ->
      src.replace 'http://', '//'
   {
      restrict: 'AC'
      link: ($scope, elem) ->
         $scope.$watch 'component.content', updateBodyFn = (newValue, oldValue) ->
            return if newValue is oldValue
            contentSrc = sslizeImageSrc($scope.component.content)
            elem.css backgroundImage: "url(#{contentSrc})"
         updateBodyFn true
   }
])

.directive('componentEditModal', ['contentAssetsService', (contentAssetsService) ->
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
      $scope.setContentAndLinkHref = (id, name, content, linkHref) -> ->
         $scope.component.id = id
         $scope.component.name = name
         $scope.component.content = content
         $scope.component.linkHref = linkHref
         true
   ]
   link: ($scope, elem) ->
      w1 = $scope.$on 'component:editme', (ev, component, isNewComponent) ->
         modalEl = $scope.modalEl = elem.children('.modal').first()
         $scope.component = component
         $scope.choosingType = isNewComponent
         $scope.choosingContent = false
         $scope.$apply()
         modalEl.modal()
         false
      w2 = $scope.$watch 'choosingContent', (newValue, oldValue) ->
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
      # clean up when the scope is destroyed
      $scope.$on 'destroy', ->
         w1()
         w2()
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

.directive('appliesBranding', ['$route', '$rootScope', ($route, $rootScope) ->
   sslizeImageSrc = (src='') ->
      src.replace 'http://', '//'
   {
      link: ($scope, elem, attrs) ->
         $rootScope.$on 'branding:apply', (ev, _brandingData={}) ->
            return if not _.isObject(_brandingData) or _.isEmpty(_brandingData)
            [_styles, _attrs] = [{}, {}]
            types = (attrs?.brandingType or 'page').split(' ')
            types.forEach (_brandingType) ->
               _.extend _styles, switch _brandingType
                  when 'html-and-body'
                     # when branded the html and body els should prevent vertical scrolling
                     overflowY:          'hidden'
                  when 'page', 'main-view-container'
                     color:              _brandingData.textColour
                     backgroundColor:    _brandingData.pageBgColour
                  when 'left-and-right-borders'
                     borderLeftColor:    _brandingData.barBgColour
                     borderRightColor:   _brandingData.barBgColour
                     borderBottomColor:  _brandingData.barBgColour
                  when 'editor-viewer'
                     borderBottomColor:  _brandingData.barBgColour
                  when 'top-bar'
                     backgroundColor:    _brandingData.barBgColour
                  else {}
               _.extend _attrs, switch _brandingType
                  when 'top-bar-logo'
                     src: sslizeImageSrc(_brandingData.logoSrcUrl)
                  else {}
            elem.attr _attrs
            elem.css  _styles
            elem.addClass 'branding-applied' if types.length

         $rootScope.$on '$routeChangeSuccess', (event, current) ->
            isBrandedRoute = $route.current?.$$route?.showBranding
            unless isBrandedRoute
               # remove branding on element
               elem.attr style: ''
               elem.removeClass 'branding-applied'
   }
])

.directive('hidesWhenBrandingApplied', ['$rootScope', ($rootScope) ->
   link: ($scope, elem) ->
      $rootScope.$on 'branding:hidechrome', ->
         elem.addClass 'hide'
])

.directive('authorContactDetailsFooterLabel', [ ->
   scope =
      contactName:  '='
      contactEmail: '='
      contactPhone: '='
   {
      restrict: 'AC'
      link: ($scope, elem, attrs) ->
         refreshContactInfoFn = ->
            elem.empty()
            values = Object.keys(scope).map (key) ->
               $scope[key]
            values = _.compact values
            values.forEach (value, idx) ->
               $("<span class='contact-field contact-field-#{idx}'>#{value}</span>").appendTo elem
            $("<span>Contact </span>").prependTo(elem) if values.length
         Object.keys(scope).map (key) ->
            $scope.$watch key, refreshContactInfoFn
         refreshContactInfoFn()
   }
])

.directive('loadingSpinner', [ ->
   restrict: 'AC'
   link: ($scope, elem, attrs) ->
      Spinner = require('spinner')
      spinner = new Spinner
      spinner.size parseInt(attrs.spinnerSize) if attrs?.spinnerSize
      elem
         .empty()
         .append spinner.el
])
