/**
 * Widget Footer Directive
 */

angular
    .module('RosaABF')
    .directive('rdWidgetFooter', rdWidgetFooter);

function rdWidgetFooter() {
    var directive = {
        transclude: true,
        replace: true,
        template: '<div class="widget-footer" ng-transclude></div>',
        restrict: 'E'
    };
    return directive;
};