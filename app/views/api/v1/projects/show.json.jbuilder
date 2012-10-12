json.project do |json|
  json.(@project, :id, :name, :visibility, :description, :ancestry, :has_issues, :has_wiki,
                  :default_branch, :is_package, :average_build_time)
  json.created_at @project.created_at.to_i
  json.updated_at @project.updated_at.to_i
  json.owner do |json_owner|
    json_owner.(@project.owner, :id, :name)
    json_owner.type @project.owner_type
    json_owner.url url_for(@project.owner)
  end
  json.repositories @project.repositories do |json_repos, repo|
    json_repos.(repo, :id, :name)
    json_repos.url api_v1_repository_path(repo.name, :format => :json)
    json_repos.platform do |json_platform|
      json_platform.(repo.platform, :id, :name)
      json_platform.url api_v1_platform_path(repo.platform, :format => :json)
    end
  end
end

json.url api_v1_project_path(@project, :format => :json)