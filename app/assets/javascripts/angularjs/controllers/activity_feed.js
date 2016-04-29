RosaABF.controller('ActivityFeedController', ['$scope', 'ActivityService', 'ProjectSelectService',
function($scope, ActivityService, ProjectSelectService) {
  $scope.feed = [];
  $scope.next_link_present = false;
  $scope.owner_tmp = "";
  $scope.project_tmp = "";
  $scope.no_loading = false;

  var owner_uname, project_name;

  $scope.getFeed = function(options, no_loading) {
    if($scope.requesting) {
      return;
    }
    $scope.no_loading = no_loading;
    if(ProjectSelectService.project) {
      if(!options) {
        options = {};
      }
      var split = ProjectSelectService.project.split('/');
      options.owner_uname = split[0];
      options.project_name = split[1];
    }
    $scope.requesting = true;
    ActivityService.getFeed(options).then(function(res) {
      $scope.requesting = false;
      $scope.next_link_present = res.next_link_present;
      $scope.feed = res.feed;
    });
  }

  $scope.$watch(function() {
    return ProjectSelectService.project;
  }, function() {
    $scope.getFeed();
  });

  $scope.getFeed();
}]);