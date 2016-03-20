//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require js-routes

//= require bootstrap-sprockets

//= require angular
//= require angular-sanitize
//= require angular-ui-bootstrap-tpls
//= require angular-i18n

//= require angular-resource
//= require ng-rails-csrf
//= require angular-cookies
//= require soundmanager2-nodebug-jsmin

//= require angular-rails-templates

//= require moment

//= require_tree ./angularjs
//= require loading-bar

//= require underscore

//= require notifyjs
//= require notifyjs/styles/bootstrap/notify-bootstrap

//= require lib/Chart
//= require lib/bootstrap-typeahead
//= require lib/custom-bootstrap-typeahead

//= require extra/scroller

//= require_self

$(document).ready(function() {
  $('.datetime_moment').each(function() {
    var mtime = moment($(this).attr('origin_datetime'), 'YYYY-MM-DD HH:mm Z');
    $(this).attr('title', mtime.utc().format('YYYY-MM-DD HH:mm:ss UTC'));
  });

  window.updateTime = function () {
    $('.datetime_moment').each(function() {
      var time = moment($(this).attr('origin_datetime'), 'YYYY-MM-DD HH:mm Z');
      $(this).html(time.format('D MMM YYYY, HH:mm') + ' (' + time.fromNow() + ')');
    });
  };

  updateTime();
  setInterval( updateTime, 15000 );

});
