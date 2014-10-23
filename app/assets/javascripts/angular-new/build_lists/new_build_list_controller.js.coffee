NewBuildListController = (dataservice) ->

  isBuildForMainPlatform = ->
    result = _.select(vm.platforms, (e) ->
      e.id is vm.build_for_platform_id
    )
    result.length is 1

  defaultSaveToRepository = ->
    return null unless vm.save_to_repositories
    return vm.save_to_repositories[0] unless vm.save_to_repository_id

    result = _.select(vm.save_to_repositories, (e) ->
      e.repo_id is vm.save_to_repository_id
    )
    return vm.save_to_repositories[0] if result.length is 0
    result[0]

  defaultProjectVersion = ->
    return null unless vm.project_versions

    result = _.select(vm.project_versions, (e) ->
      e.name is vm.project_version_name
    )
    return vm.project_versions[0] if result.length
    result[0]

  vm = this

  vm.selectSaveToRepository = ->
    setProjectVersion = ->
      return null unless vm.project_versions

      result = _.select(vm.project_versions, (e) ->
        e.name is vm.project_version_name
      )
      return vm.project_versions[0] unless result.length
      result[0]

    changeStatusRepositories = ->
      return unless vm.platforms
      vm.is_build_for_main_platform = isBuildForMainPlatform()
      _.each(vm.platforms, (e) ->
        _.each(e.repositories, (r) ->
          if e.id isnt vm.build_for_platform_id
            r.checked = false
          else
            r.checked = true if r.name == 'main' or r.name == 'base'
        )

      )

    updateDefaultArches = ->
      return unless vm.arches
      _.each(vm.arches, (a) ->
        a.checked = _.contains(vm.save_to_repository.default_arches, a.id)
      )

    vm.build_for_platform_id = vm.save_to_repository.platform_id
    vm.project_version_name = vm.save_to_repository.platform_name
    vm.project_version = setProjectVersion()
    changeStatusRepositories()
    updateDefaultArches()

  init = (dataservice) ->

    vm.build_for_platform_id      = dataservice.build_for_platform_id
    vm.platforms                  = dataservice.platforms
    vm.save_to_repositories       = dataservice.save_to_repositories
    vm.project_versions           = dataservice.project_versions

    vm.project_version_name       = dataservice.project_version
    vm.project_version            = defaultProjectVersion()
    vm.save_to_repository_id      = dataservice.save_to_repository_id
    vm.save_to_repository         = defaultSaveToRepository()

    vm.arches                     = dataservice.arches

    vm.hidePlatform               = (platform) ->
      vm.is_build_for_main_platform and platform.id isnt vm.build_for_platform_id

    vm.is_build_for_main_platform = isBuildForMainPlatform()

  init(dataservice)

angular
  .module("RosaABF")
  .controller "NewBuildListController", NewBuildListController

NewBuildListController.$inject = ["newBuildInitializer"]
