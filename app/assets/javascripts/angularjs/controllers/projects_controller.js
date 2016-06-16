RosaABF.controller('ProjectsController', ['$scope', 'ProjectsService', 
function($scope, ProjectsService) {
  $scope.projects = null;
  $scope.search = "";

  var promiseResolve = function(projects) {
    $scope.requesting = false;
    $scope.projects = projects;
  }

  $scope.searchProjects = function(search) {
    $scope.requesting = true;
    $scope.search = search;
    ProjectsService.getProjects(search).then(promiseResolve);
  }

  $scope.requesting = true;
  ProjectsService.getProjects().then(promiseResolve);
}]);