angular.module("RosaABF").factory('ProjectInfoService', ["$http", function($http) {
  var ProjectInfoService = {};

  ProjectInfoService.getProjectInfo = function(name_with_owner) {
    return $http.get(Routes.project_info_path(name_with_owner, { format: 'json' })).then(function(res) {
      return res.data.project_info;
    });
  }

  return ProjectInfoService;
}]);