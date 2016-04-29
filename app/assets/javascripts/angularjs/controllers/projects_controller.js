RosaABF.controller('ProjectsController', ['$scope', 'ProjectsService', 'ProjectSelectService', 
function($scope, ProjectsService, ProjectSelectService) {
  $scope.projects = null;
  $scope.ProjectSelectService = ProjectSelectService;
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

  $scope.selectProject = function(project) {
    ProjectSelectService.project = project;
  }

  $scope.requesting = true;
  ProjectsService.getProjects().then(promiseResolve);
}]);