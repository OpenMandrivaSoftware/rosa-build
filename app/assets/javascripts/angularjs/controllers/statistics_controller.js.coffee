RosaABF.controller 'StatisticsController', ['$scope', '$http', '$timeout', ($scope, $http, $timeout) ->

  $scope.users_or_groups          = null
  $scope.range                    = 'last_30_days'
  $scope.range_start              = $('#range_start').attr('value')
  $scope.range_end                = $('#range_end').attr('value')
  $scope.loading                  = false
  $scope.statistics               = {}
  $scope.statistics_path          = '/statistics'

  $scope.colors                   = [
    '56, 132, 158',
    '77, 169, 68',
    '241, 128, 73',
    '174, 199, 232'
  ]
  $scope.charts                   = {}

  $scope.dateOptions =
    formatYear:   'yy'
    startingDay:  1

  $scope.init = ->
    $scope.update()
    true

  $scope.$on "activate_stats_tab", (event, args) ->
    if Object.keys($scope.statistics).length is 0
      $timeout $scope.init, 1000

    true

  $scope.openRangeStart = ($event) ->
    return if $scope.loading
    $event.preventDefault()
    $event.stopPropagation()
    $scope.range_start_opened = true

  $scope.openRangeEnd = ($event) ->
    return if $scope.loading
    $event.preventDefault()
    $event.stopPropagation()
    $scope.range_end_opened = true

  $scope.prepareRange = ->
    range_start = new Date($scope.range_start)
    range_end   = new Date($scope.range_end)

    if range_start > range_end
      tmp                 = $scope.range_start
      $scope.range_start  = $scope.range_end
      $scope.range_end    = tmp

  $scope.update = ->
    return if $scope.loading
    $scope.loading    = true
    $scope.statistics = {}

    $scope.prepareRange()
    $('.doughnut-legend').remove()

    params =
      range:            $scope.range
      range_start:      $scope.range_start
      range_end:        $scope.range_end
      users_or_groups:  $scope.users_or_groups
      format:       'json'
    console.log($scope.users_or_groups)
    $http.get($scope.statistics_path, params: params).success (results) ->
      $scope.statistics = results

      $scope.loading    = false

      # BuildLists
      if $scope.statistics.build_lists
        $scope.initBuildListsChart()

    .error (data, status, headers, config) ->
      console.log 'error:'
      $scope.loading    = false

  $scope.dateChart = (id, collections) ->
    new_collections = $.grep collections, ( c ) ->
      return c

    if collections.length == new_collections.length
      $scope.charts[id].destroy() if $scope.charts[id]

      points = collections[0]
      factor = points.length // 45 + 1

      tooltipTitles = []
      labels        = _.map points, (d, index) ->
        x = d.x
        tooltipTitles.push x
        if index %% factor == 0
          x
        else
          ''

      datasets  = _.map collections, (collection, index) ->
        data = _.map collection, (d) ->
          d.y

        dataset =
          fillColor:        "rgba(#{ $scope.colors[index] }, 0.1)"
          strokeColor:      "rgba(#{ $scope.colors[index] }, 1)"
          pointColor:       "rgba(#{ $scope.colors[index] }, 1)"
          pointStrokeColor: "#fff"
          data:             data

      data    =
        datasets:       datasets
        # We display only limited count of labels on X axis, but tooltips should have titles
        # See: Chart.js "Added by avokhmin"
        labels:         labels
        tooltipTitles:  tooltipTitles

      options =
        responsive: true

      chart = $(id)
      chart.attr
        width:  chart.parent().width()
        height: chart.parent().outerHeight()

      context           = chart[0].getContext('2d')
      $scope.charts[id] = new Chart(context).Line(data, options)

  $scope.initBuildListsChart = ->
    $scope.dateChart '#build_lists_chart', [
      $scope.statistics.build_lists.build_started,
      $scope.statistics.build_lists.success,
      $scope.statistics.build_lists.build_error,
      $scope.statistics.build_lists.build_published
    ]

]