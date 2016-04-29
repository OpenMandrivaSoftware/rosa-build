RosaABF.controller('ProjectInfoController', ['$scope', 'ProjectInfoService', 'ProjectSelectService', 
function($scope, ProjectInfoService, ProjectSelectService) {
  $scope.widget_title = "";
  $scope.$watch(function() {
    return ProjectSelectService.load_project_info;
  }, function() {
    var project = ProjectSelectService.load_project_info;
    if(project) {
      $scope.requesting = true;
      ProjectSelectService.disable_pi = true;
      ProjectInfoService.getProjectInfo(project).then(function(res) {
        $scope.project = project;
        $scope.project_info = res;
        $scope.requesting = false;
        $scope.widget_title = " | " + project;
        ProjectSelectService.disable_pi = false;
      });
    }
    else {
      $scope.project_info = null;
      $scope.project = "";
      $scope.widget_title = "";
    }
  });
}]);
