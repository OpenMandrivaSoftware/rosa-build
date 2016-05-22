RosaABF.controller('MembersController', ['$scope', '$http', 
function($scope, $http) {
  $scope.getUsers = function(name) {
    var params = {format: 'json', query: name};
    return $http.get(Routes.autocomplete_user_uname_autocompletes_path(params)).then(function(response) {
      return response.data;
    });
  }

  $scope.select = function($item, $model, $name) {
    $scope.memberId = $item.id;
  }
}]);