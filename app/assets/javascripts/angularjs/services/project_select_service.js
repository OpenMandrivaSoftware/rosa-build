angular.module("RosaABF").factory('ProjectSelectService', function() {
  return {
    project: "",
    disable_bl: false,
    disable_pi: false,
    disable: function() {
      return this.disable_bl || this.disable_pi;
    }
  };
});