RosaABF.controller 'ProfileController', ['$scope', '$http', ($scope, $http) ->

  $scope.processing  = true
  $scope.projects    = []
  $scope.page        = null
  $scope.total_items = null
  $scope.term        = null

  $scope.init = (subject) ->
    $scope.subject = subject
    $scope.refresh()
    return

  $scope.refresh = ->
    $scope.processing = true

    params  =
      term:         $scope.term
      visibility:   'all'
      page:         $scope.page
      format:       'json'

    $http.get Routes.user_path($scope.subject), params: params
    .success (data) ->
      $scope.projects    = data.projects
      $scope.total_items = data.total_items
      $scope.processing  = false
    .error ->
      $scope.projects    = []
      $scope.processing  = false

    true

  $scope.search = (term) ->
    $scope.term = term
    $scope.refresh()
    return

  $scope.goToPage = (number) ->
    $scope.page = number
    $scope.refresh()
    return


  return
]