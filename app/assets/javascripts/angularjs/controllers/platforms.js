RosaABF.controller('PlatformsController', ['$scope', 'PlatformsService', function($scope, PlatformsService) {
  $scope.platforms = null;

  $scope.requesting = true;
  PlatformsService.getPlatforms().then(function(platforms) {
    $scope.requesting = false;
    $scope.platforms = platforms;
  });
}]);
