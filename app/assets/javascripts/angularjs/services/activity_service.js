angular.module("RosaABF").factory('ActivityService', ["$http", "$filter", function($http, $filter) {
  var ActivityService = {};

  var feed;
  var next_page_link = null;

  var last_date;
  var last_is_own = false;
  var processFeed = function(feed) {
    var res = [];

    _.each(feed, function(item) {
      var cur_date = $filter('amDateFormat')(item.date, 'll')
      if(cur_date != last_date) {
        res.push({kind: 'new_day', date: cur_date, class: 'timeline-day'});
        last_date = cur_date;
      }
      res.push(item);
    });

    return res;
  }

  ActivityService.getFeed = function(options) {
    if(Object.prototype.toString.apply(options) != '[object Object]') {
      options = {is_own: last_is_own, load_next_page: false};
    }

    var url;
    if(!options['load_next_page']) {
      last_date = null;
      feed = {};
      params = {format: 'json'};
      if(options['owner_uname']) {
        params['owner_filter'] = options['owner_uname'];
      }
      if(options['project_name']) {
        params['project_name_filter'] = options['project_name'];
      }
      last_is_own = options['is_own'];
      url = options['is_own'] ? Routes.own_activity_path(params) : Routes.activity_feeds_path(params);
    }
    else {
      if(!next_page_link) {
        return false;
      }

      url = next_page_link;
    }

    return $http.get(url).then(function(res) {
      next_page_link = res.data.next_page_link;

      var new_feed = processFeed(res.data.feed);
      var ret;
      if(options['load_next_page']) {
        ret = feed;
        ret.push.apply(ret, new_feed);
      }
      else {
        feed = ret = new_feed;
      }

      return {feed: ret, next_link_present: !!next_page_link};
    });
  }

  ActivityService.getOwnersList = function(val) {
    var path = Routes.get_owners_list_path({term: val});

    return $http.get(path).then(function(res) {
      return res.data;
    });
  }

  ActivityService.getProjectNamesList = function(owner_uname, val) {
    var path = Routes.get_project_names_list_path({owner_uname: owner_uname, term: val});

    return $http.get(path).then(function(res) {
      return res.data;
    });
  }

  return ActivityService;
}]);