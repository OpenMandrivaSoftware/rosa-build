RosaABF.controller 'RepositoryProjectsController', 
['$scope', '$http', 'confirmMessage', 
  ($scope, $http, confirmMessage) ->
    $scope.page           = 1
    $scope.owner_name     = ""
    $scope.project_name   = ""
    $scope.processing     = true
    $scope.projects       = []
    $scope.total_items    = null

    $scope.init = (added, repository_id, platform_id) ->
      $scope.added = added
      $scope.platform_id = platform_id
      $scope.repository_id = repository_id
      $scope.refresh()
      true

    $scope.refresh = ->
      $scope.processing = true

      params  =
        added:        $scope.added
        owner_name:   $scope.owner_name
        project_name: $scope.project_name
        page:         $scope.page
        format:       'json'

      path = Routes.projects_list_platform_repository_path $scope.platform_id, $scope.repository_id
      $http.get(path, params: params).success (data) ->
        $scope.projects    = data.projects
        $scope.total_items = data.total_items
        $scope.processing  = false
      .error ->
        $scope.projects    = []
        $scope.processing  = false

      true

    $scope.search = (owner, name) ->
      $scope.owner_name = owner
      $scope.project_name = name
      $scope.refresh()
      true

    $scope.goToPage = (number) ->
      $scope.page = number
      $scope.refresh()
      true

    $scope.removeProject = (project) ->
      return false unless confirmMessage.show()
      $http.delete(project.remove_path).success (data) ->
        $.notify(data.message, 'success')

      $scope.projects = _.reject($scope.projects, (pr) ->
        return pr.id is project.id
      )
      false


    return
]