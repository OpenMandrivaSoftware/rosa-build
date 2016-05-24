RosaABF.controller('RosaABFController', ['$scope', 'LocalesHelper', 'SoundNotificationsHelper', '$timeout', '$cookies',
                   function($scope, LocalesHelper, SoundNotificationsHelper, $timeout, $cookies) {

  $scope.hideAlerts = false;
  $scope.init = function(locale, sound_notifications) {
  	LocalesHelper.setLocale(locale);
    //moment.locale(locale);
    SoundNotificationsHelper.enabled(sound_notifications);
    $timeout(function() { $scope.hideAlerts = true; }, 5000);
  }

  if(typeof $cookies.get('toggle') == 'undefined') {
    var mobileView = 992;

    if (window.innerWidth >= mobileView) {
      $scope.toggle = true;
    } 
    else {
      $scope.toggle = false;
    }
  }
  else {
    $scope.toggle = $cookies.get('toggle') == 'true' ? true : false;
  }

  $scope.toggleSidebar = function() {
    $scope.toggle = !$scope.toggle;
    $cookies.put("toggle", $scope.toggle);
  };

}]);
