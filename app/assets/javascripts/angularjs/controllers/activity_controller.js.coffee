ActivityController = ($scope, $http, $timeout, $q, $filter, $location, ActivityFilter) ->

  calculateChangeDate = (feed)->
    prev_date = null
    _.each(feed, (event)->
      cur_date  = $filter('amDateFormat')(event.date, 'll')
      event.is_date_changed = cur_date isnt prev_date
      prev_date = cur_date
    )

  $scope.$watch (->
    vm.current_activity_tab.owner_uname_filter_tmp
  ), () ->
    vm.selectOwnerFilter({uname: null}, null, null) unless vm.current_activity_tab.owner_uname_filter_tmp

  $scope.$watch (->
    vm.current_activity_tab.project_name_filter_tmp
  ), () ->
    vm.selectProjectNameFilter({name: null}, null, null) unless vm.current_activity_tab.project_name_filter_tmp


  vm = this

  vm.processing   = false
  vm.activity_tab =
    filter: 'build'
    build: {}
    owner_filter: null
    project_name_filter: null
    owner_uname_filter_tmp: null
    project_name_filter_tmp: null

  vm.own_activity_tab = $.extend({}, vm.activity_tab)
  vm.current_activity_tab = vm.activity_tab

  vm.init = (active_tab)->
    switch active_tab
      when 'activity'
        vm.activity_tab.active  = true
        vm.current_activity_tab = vm.activity_tab
      when 'own_activity'
        vm.own_activity_tab.active = true
        vm.current_activity_tab    = vm.own_activity_tab
    true

  vm.getContent = (tab)->
    switch tab
      when 'activity'
        vm.activity_tab.active      = true
        vm.own_activity_tab.active  = false
        vm.current_activity_tab     = vm.activity_tab
        vm.getActivityContent()
        if $location.path() isnt '/'
          $location.path('/').replace()

      when 'own_activity'
        vm.activity_tab.active      = false
        vm.own_activity_tab.active  = true
        vm.current_activity_tab     = vm.own_activity_tab
        vm.getActivityContent()
        if $location.path() isnt '/own_activity'
          $location.path('/own_activity').replace()

  vm.getTimeLinefaClass = (content)->
    template = switch content.kind
      when 'build_list_notification'   then 'btn-success fa-gear'
      else 'btn-warning fa-question'
    template

  vm.getCurActivity = ()->
    vm.current_activity_tab[vm.current_activity_tab.filter]

  vm.getTemplate = (content)->
    content.kind + '.html'

  vm.load_more = ()->
    cur_tab = vm.getCurActivity()
    path    = cur_tab.next_page_link
    return unless path

    $http.get(path).then (res)->
      cur_tab.feed.push.apply(cur_tab.feed, res.data.feed)
      cur_tab.next_page_link = res.data.next_page_link

  vm.getActivityContent = ()->
    vm.processing = true
    options =
      owner_filter:        vm.current_activity_tab.owner_filter
      project_name_filter: vm.current_activity_tab.project_name_filter
      format:              'json'

    if vm.activity_tab.active
      path = Routes.root_path(options)
    else
      path = Routes.own_activity_path(options)

    $http.get(path).then (res)->
      feed = res.data.feed
      vm.getCurActivity().feed = feed
      vm.getCurActivity().next_page_link = res.data.next_page_link
      calculateChangeDate(feed)
      vm.processing = false
      true

  vm.getOwnersList = (value)->
    return [] if value.length < 1
    ActivityFilter.get_owners(value)

  vm.selectOwnerFilter = (item, model, label)->
    return if vm.current_activity_tab.owner_filter is item.uname

    vm.current_activity_tab.owner_filter            = item.uname
    vm.current_activity_tab.project_name_filter     = null
    vm.current_activity_tab.project_name_filter_tmp = null
    vm.getActivityContent()
    true

  vm.getProjectNamesList = (value)->
    return [] if value.length < 1
    ActivityFilter.get_project_names(vm.current_activity_tab.owner_filter, value)

  vm.selectProjectNameFilter = (item, model, label)->
    return if vm.current_activity_tab.project_name_filter is item.name
    vm.current_activity_tab.project_name_filter = item.name
    vm.getActivityContent()
    true

angular
  .module("RosaABF")
  .controller "ActivityController", ActivityController

ActivityController.$inject = ['$scope', '$http', '$timeout', '$q', '$filter', '$location', 'ActivityFilter']
