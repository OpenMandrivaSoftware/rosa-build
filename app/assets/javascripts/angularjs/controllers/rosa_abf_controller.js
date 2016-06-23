RosaABF.controller('RosaABFController', ['$scope', 'LocalesHelper', 'SoundNotificationsHelper', '$timeout', '$cookies',
                   function($scope, LocalesHelper, SoundNotificationsHelper, $timeout, $cookies) {

  $scope.hideAlerts = false;
  $scope.init = function(locale, sound_notifications) {
  	LocalesHelper.setLocale(locale);
    //moment.locale(locale);
    SoundNotificationsHelper.enabled(sound_notifications);
    $timeout(function() { $scope.hideAlerts = true; }, 5000);
  }

  var mobileView = 992, toggle;

  if (window.innerWidth >= mobileView) {
    toggle = true;
  } 
  else {
    toggle = false;
  }

  if(toggle) {
    if(typeof $cookies.get('toggle') == 'undefined') {
      $scope.toggle = toggle;
    }
    else {
      $scope.toggle = $cookies.get('toggle') == 'true' ? true : false;
    }
  }
  else {
    $scope.toggle = false;
  }

  $scope.toggleSidebar = function() {
    $scope.toggle = !$scope.toggle;
    if(toggle) {
      $cookies.put("toggle", $scope.toggle);
    }
  };

}]);
