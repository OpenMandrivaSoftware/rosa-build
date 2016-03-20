RosaABF.controller 'BuildListController', ['$scope', '$http', '$timeout', 'SoundNotificationsHelper', ($scope, $http, $timeout, SoundNotificationsHelper) ->

  $scope.id                 = $('#build_list_id').val()
  $scope.build_list         = null
  $scope.subject            = {} # See: shared/build_results
  # Statuses: advisory_not_found, server_error, continue_input
  $scope.term               = ''

  $scope.getBuildList = ->
    $http.get Routes.build_list_path($scope.id, {format: 'json'})
    .success (results) ->
      build_list = new BuildList(results.build_list)
      if $scope.build_list && $scope.build_list.status != build_list.status
        SoundNotificationsHelper.buildStatusChanged()
      $scope.build_list = $scope.subject = build_list

  $scope.canRefresh = ->
    return true   unless $scope.build_list

    show_dependent_projects = _.find $scope.build_list.packages, (p) ->
      p.show_dependent_projects

    return false if show_dependent_projects

    statuses = [
      666,  # BuildList::BUILD_ERROR
      5000, # BuildList::BUILD_CANCELED
      6000, # BuildList::BUILD_PUBLISHED
      8000, # BuildList::FAILED_PUBLISH
      9000, # BuildList::REJECTED_PUBLISH
    ]

    if !_.contains(statuses, $scope.build_list.status)
      true
    else
      false

  $scope.cancelRefresh = null
  $scope.refresh = ->
    if $scope.canRefresh()
      $scope.getBuildList()
    $scope.cancelRefresh = $timeout($scope.refresh, 10000)

  $scope.refresh()
]