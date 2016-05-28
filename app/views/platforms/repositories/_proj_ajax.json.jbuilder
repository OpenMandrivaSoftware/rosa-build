json.projects @projects do |project|
  #json.visibility_class fa_visibility_icon(project)
  json.path             project_build_lists_path(project.name_with_owner)
  json.name             project.name_with_owner
  json.add_path         add_project_platform_repository_path @platform.name, @repository.name, project_id: project.id
end

json.total_items @total_items