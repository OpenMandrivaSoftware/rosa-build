json.(project, :id, :name, :visibility)
json.fullname project.name_with_owner
json.url api_v1_project_path(project.id, format: :json)
json.git_url project.git_project_address
json.maintainer do
  if project.maintainer
    json.partial! 'api/v1/maintainers/maintainer', maintainer: project.maintainer
  end
end