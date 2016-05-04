RosaABF.controller('RosaABFController', ['$scope', 'LocalesHelper', 'SoundNotificationsHelper', '$timeout',
                   function($scope, LocalesHelper, SoundNotificationsHelper, $timeout) {

  $scope.hideAlerts = false;
  $scope.init = function(locale, sound_notifications) {
  	LocalesHelper.setLocale(locale);
    //moment.locale(locale);
    SoundNotificationsHelper.enabled(sound_notifications);
    $timeout(function() { $scope.hideAlerts = true; }, 5000);
  }
  var mobileView = 992;

  $scope.getWidth = function() {
      return window.innerWidth;
  };

  $scope.$watch($scope.getWidth, function(newValue, oldValue) {
      if (newValue >= mobileView) {
        $scope.toggle = true;
      } 
      else {
        $scope.toggle = false;
      }
  });

  $scope.toggleSidebar = function() {
      $scope.toggle = !$scope.toggle;
  };

}]);
