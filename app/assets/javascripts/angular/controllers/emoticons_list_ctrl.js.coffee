App.controller 'EmoticonListCtrl', ($scope, $state, EmoticonsModel, Restangular) ->
  # Initialization Code
  if _.isUndefined $state.current.data
    EmoticonsModel.currentListType = 'all'
  else
    EmoticonsModel.currentListType = $state.current.data.currentListType
  EmoticonsModel.loader EmoticonsModel.currentListType

  # Setup the Scopes needed for this controller
  $scope.emoticons = () ->
    EmoticonsModel.currentList
  $scope.currentListType = () ->
    EmoticonsModel.currentListType

  # Controller Logic
  $scope.$watch 'currentListType()', (currentType, previousType) ->
    unless currentType == previousType
      EmoticonsModel.switchCurrentList(currentType)

  $scope.$watch 'emoticonList.length', (newval, oldval) ->
    if angular.isDefined $scope.fEmoticons
      # Bottle neck here is rebuilding the available tags in reverse for a big set (like the first tag)
      # TODO: Once we support multiple 'emoticon lists', move this into a watcher on the promise
      # TODO: Maybe use underscore's memoize here?
       unless angular.isDefined $scope.allTags
        $scope.allTags = []
        angular.forEach $scope.fEmoticons, (emoticon) ->
          $scope.allTags = $scope.allTags.concat(_.keys(emoticon.tags))
        $scope.allTags = _.uniq($scope.allTags)
        EmoticonsModel.availableTags = $scope.allTags

      if EmoticonsModel.activeTags.length > 0
        EmoticonsModel.availableTags = []
        angular.forEach $scope.fEmoticons, (emoticon) ->
          EmoticonsModel.availableTags = _.uniq(EmoticonsModel.availableTags.concat(_.keys(emoticon.tags)))
        EmoticonsModel.availableTags = _.difference(EmoticonsModel.availableTags, EmoticonsModel.activeTags)
      else
        # Handles the final delete key press
        EmoticonsModel.availableTags = $scope.allTags


  $scope.tagFilter = (emote) ->
    return emote if EmoticonsModel.activeTags.length == 0
    valid = true
    angular.forEach EmoticonsModel.activeTags, (tag) ->
      valid = false if _.indexOf(_.keys(emote.tags), tag) == -1
    if valid
      return emote
    else
      return false

  $scope.boxsizes = () ->
    _.each $scope.emoticonList, (emoticon) ->
      element_width = $('#' + emoticon.id).width()
      display_columns = 4 if element_width > 380
      display_columns = 3 if element_width <= 380
      display_columns = 2 if element_width <= 250
      display_columns = 1 if element_width <= 120
      Restangular.one('emotes', emoticon.id).put( { display_columns: display_columns})

# The proper way map and use model is this.  First load the state into the model, then make a scope method that
# fetches that state.  When you need to update the state, you write to the model, never the scope, otherwise your
# unbinding the connection to the model you created.
#  DataService.currentListType = $state.current.data.currentListType
#  $scope.currentListType =  () ->
#    DataService.currentListType