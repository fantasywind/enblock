enblock = angular.module('enblock', [])

DEFAULT = 
  MODE: 'edit'
  ORIGINAL: []
  ENABLEDTOOLS: ['paragraph', 'gallery']

# Detect for text editing return send
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

# Select element
selectElement = (element)->
  newRange = document.createRange()
  newRange.selectNode element
  selection = document.getSelection()
  selection.removeAllRanges()
  selection.addRange newRange
  return newRange

# Clean measurer
cleanMeasurer = ->
  measurer = document.querySelector '.enblock-measurer'
  if measurer?
    parent = measurer.parentNode
    # Re-create span innerHTML DOMs
    for elem in measurer.childNodes
      if elem.nodeType is 3
        newElem = document.createTextNode elem.nodeValue
      else if elem.nodeName is 'BR'
        newElem = document.createElement 'br'
      else
        continue
      parent.insertBefore newElem, measurer
    measurer.remove()
    parent.normalize()

# Get selection position from Range
getPositionFromRange = (range)->
  return false if !range instanceof Range

  # Clean measurer
  cleanMeasurer()

  if !angular.isFunction range.getBoundingClientRect
    return range.getBoundingClientRect()
  else
    measurer = document.createElement 'span'
    selectedContent = range.cloneContents()
    measurer.appendChild range.cloneContents()
    measurer.classList.add 'enblock-measurer'
    range.deleteContents()
    range.insertNode measurer
    selectElement measurer
    return {
      top: measurer.offsetTop
      left: measurer.offsetLeft
      width: measurer.offsetWidth
      height: measurer.offsetHeight
      right: measurer.offsetLeft + measurer.offsetWidth
      bottom: measurer.offsetTop + measurer.offsetHeight
    }

# Photo class for Gallery
class GalleryPhoto
  constructor: (options)->
    {meta, @containerScope, @containerElem} = options

    @status = GalleryPhoto::INITIAL
    @setSource meta.src
    @description = meta.description

    # Push to container
    @containerScope.photos.push @

  setSource: (src)->
    # Need: add link parsing and testing
    @src = src
    @status = GalleryPhoto::SOURCESET

  SOURCESET: 'sourceSet'
  INITIAL: 'initial'

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

    # Check selection status
    @checkSelection = ->
      return document.getSelection().type

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

    ### -- Utility -- ###
    # Generate Toolbar Position Style
    generateToolStyle = (position, styleCollection)->
      return false if !angular.isObject position
      styleCollection = {} if !angular.isObject styleCollection
      try
        left = parseInt(position.left - 162, 10)
        styleCollection.left = (if left > 0 then left else position.left) + 'px'
        styleCollection.top = parseInt(position.top, 10) - 36 + 'px'
      catch e
        console.error "Error for position object when set toolbar position."

      return styleCollection

    ### -- Initial Variable -- ###
    scope.showTool = false
    scope.toolStyle = {}

    # Select paragraph
    scope.select = ->
      enblock.setSelected element

    # Close toolbar when blur
    scope.blur = (e)->
      return false if e.relatedTarget and e.relatedTarget.classList.contains('enblock-paragraph-toolbutton')
      scope.showTool = false
      cleanMeasurer()

    # Check selection
    scope.checkSelection = ->
      if enblock.checkSelection() is 'Range'
        scope.showTool = true
        range = document.getSelection().getRangeAt(0)
        position = getPositionFromRange range
        scope.toolStyle = generateToolStyle position
      else
        scope.showTool = false


enblock.directive 'enblockGallery', ->
  restrict: 'CE'
  require: '^enblock'
  templateUrl: 'element-gallery.html'
  scope:
    mode: '@mode'
  transclude: true
  link: (scope, element, attrs, enblock)->
    # Photo List
    scope.photos = []

    # Constant
    scope.SQUARE = 'square'
    scope.SINGLE = 'single'

    allowModes = [scope.SQUARE, scope.SINGLE]

    # Gallery Mode
    attrs.$set 'mode', scope.SQUARE if !attrs.mode? or allowModes.indexOf(attrs.mode) is -1

    # Push original images
    originImages = element[0].querySelectorAll '.enblock-gallery-origin > .enblock-gallery-image-source'

    for image in originImages
      if image.dataset?
        photo = new GalleryPhoto
          meta: image.dataset
          containerScope: scope
          containerElem: element

    scope.select = ->
      enblock.setSelected element



