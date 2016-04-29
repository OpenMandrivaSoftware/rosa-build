RosaABF.controller('RosaABFController', ['$scope', 'LocalesHelper', 'SoundNotificationsHelper', '$timeout',
                   function($scope, LocalesHelper, SoundNotificationsHelper, $timeout) {

  $scope.hideAlerts = false;
  $scope.init = function(locale, sound_notifications) {
  	LocalesHelper.setLocale(locale);
    //moment.locale(locale);
    SoundNotificationsHelper.enabled(sound_notifications);
    $timeout(function() { $scope.hideAlerts = true; }, 5000);
    console.log($scope);
  }
}]);
