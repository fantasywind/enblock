enblock = angular.module('enblock', [])

DEFAULT = 
  MODE: 'edit'
  ORIGINAL: []
  ENABLEDTOOLS: ['paragraph', 'gallery']

contentKeypress = (e)->
  # Insert <br> when press return key
  if (e.keyCode or e.which) is 13
    e.preventDefault()
    _selection = document.getSelection()
    if (_range = _selection.getRangeAt(0)) instanceof Range
      _br = document.createElement('br')
      _range.insertNode _br
      _nextText = _br.nextSibling
      _range.setStart _nextText, 0
      _range.setEnd _nextText, 0
      _selection.empty()
      _selection.addRange _range

enblock.directive 'enblock', ->
  restrict: 'CE'
  templateUrl: 'construct.html'
  transclude: true
  scope:
    controller: '=controller'
    setMode: '=mode'
    setTools: '=enabledTools'
  compile: (element, attrs)->
    if attrs.controller is undefined
      element.addClass 'enblockInitialFailed'
      console.error ('enblock Error: You must set "controller" attribute in enblock directive.') 

  controller: ($scope, $element)->
    # Remove element if controll setting missing.
    return $element.remove() if $element.hasClass 'enblockInitialFailed'

    # Set default value if no set.
    $scope.tools = $scope.setTools or DEFAULT.ENABLEDTOOLS
    $scope.mode = $scope.setMode or DEFAULT.MODE

    _contentField = $element[0].querySelector '.enblock-content'
    _contentField.addEventListener 'keypress', contentKeypress, false

    $scope.controller = {}

    # @property
    $scope.selected = null # Selected element (editing)

    # Set selected element class
    @setSelected = (elem)->
      @clearSelected() if !!$scope.selected
      elem.addClass 'enblock-selected'
      $scope.selected = elem
      return true

    # Clear selected element class
    @clearSelected = ->
      $scope.selected.removeClass 'enblock-selected'
      $scope.selected = null
      return true

    return @

enblock.directive 'enblockToolbar', ->
  restrict: 'CE'
  require: '^enblock'
  templateUrl: 'toolbar.html'
  scope:
    enabled: '=enabledTools'
  link: (scope, element, attrs, enblock)->

enblock.directive 'enblockParagraph', ->
  restrict: 'CE'
  require: '^enblock'
  transclude: true
  templateUrl: 'element-paragraph.html'
  scope: {}
  link: (scope, element, attrs, enblock)->
    scope.select = ->
      enblock.setSelected element

enblock.directive 'enblockGallery', ->
  restrict: 'CE'
  require: '^enblock'
  templateUrl: 'element-gallery.html'
  scope: {}
  link: (scope, element, attrs, enblock)->
