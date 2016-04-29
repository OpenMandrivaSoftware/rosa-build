angular.module("RosaABF").factory('ProjectsService', ["$http", function($http) {
  var ProjectsService = {};

  ProjectsService.getProjects = function(search) {
    var params = { format: 'json' };
    if(search) {
      params.search = search;
    }
    return $http.get(Routes.projects_path(params)).then(function(res) {
      return res.data.projects;
    });
  }

  return ProjectsService;
}]);