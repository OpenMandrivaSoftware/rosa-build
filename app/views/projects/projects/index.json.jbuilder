json.projects do
  json.array!(@projects) do |item|
    json.cache! item, expires_in: 1.minutes do
      json.name_with_owner     item.name_with_owner
      json.project_link        project_build_lists_path(item.name_with_owner)
      json.new_build_list_link new_project_build_list_path(item.name_with_owner)
      json.edit_link           edit_project_path(item) if policy(item).update?
    end
  end
end