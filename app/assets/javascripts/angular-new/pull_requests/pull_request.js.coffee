ApiPullRequestService = ($resource) ->

  PullRequestResource = $resource("/:owner/:project/pull_requests/:serial_id?format=json",
    owner:     "@pull_request.to_ref.project.owner_uname"
    project:   "@pull_request.to_ref.project.name"
    serial_id: "@pull_request.number"
  ,
    update:
      method: "PUT"
      isArray: false

    merge:
      url: "/:owner/:project/pull_requests/:serial_id/merge"
      format: "json"
      method: "PUT"
      isArray: false
  )
  resource: PullRequestResource

angular
  .module("RosaABF")
  .factory "ApiPullRequest", ApiPullRequestService

ApiPullRequestService.$inject = ['$resource']
