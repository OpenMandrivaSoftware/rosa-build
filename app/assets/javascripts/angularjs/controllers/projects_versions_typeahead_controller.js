RosaABF.controller('ProjectsVersionsTypeaheadController', ['$scope', '$http', '$sce', function($scope, $http, $sce) {
  $scope.loadingVersions = false;

  $scope.init = function(platform, projectName, projectId, projectVersion) {
    $scope.platform = platform;
    $scope.project = projectName;
    $scope.projectId = projectId;
    if(projectId) {
      var params = {id: projectId};
      if(projectVersion) {
        params.projectVersion = projectVersion;
      }
      $scope.selectProject(params);
    }
  }

  $scope.getProjects = function(query) {
    var params = { query: query, format: 'json'};
    return $http.get(Routes.autocomplete_project_platform_products_path($scope.platform, params)).then(function(res) {
      return res.data;
    });
  }

  $scope.selectProject = function($item) {
    $scope.projectId = $item.id;
    $scope.loadingVersions = true;
    var params = {project_id: $item.id, format: 'json', project_version: $item.projectVersion};
    $http.get(Routes.project_versions_platform_products_path($scope.platform, params)).then(function(res) {
      $scope.projectVersions = $sce.trustAsHtml(res.data.project_versions);
      $scope.loadingVersions = false;
    });
  }
}]);