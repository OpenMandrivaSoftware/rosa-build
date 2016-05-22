/**
 * Widget Header Directive
 */

angular
    .module('RosaABF')
    .directive('rdWidgetHeader', rdWidgetTitle);

function rdWidgetTitle() {
    var directive = {
        requires: '^rdWidget',
        replace: true,
        scope: {
            title: '@',
            icon: '@',
            customClass: '@'
        },
        transclude: true,
        template: '<div class="widget-header"><div class="row"><div class="pull-left"><i class="fa" ng-class="icon"></i> {{title}} </div><div class="pull-right" ng-class="[{\'col-xs-6\': !customClass, \'col-sm-4\': !customClass}, customClass]" ng-transclude></div></div></div>',
        restrict: 'E'
    };
    return directive;
};