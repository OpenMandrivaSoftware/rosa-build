angular.module("RosaABF").factory('PlatformsService', ["$http", function($http) {
  var PlatformsService = {};

  PlatformsService.getPlatforms = function() {
    return $http.get(Routes.platforms_path({ format: 'json' })).then(function(res) {
      return res.data.platforms;
    });
  }

  return PlatformsService;
}]);