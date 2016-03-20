json.user do
  json.(@user, :id)
  json.notifiers do
    json.(@user.notifier, :can_notify, :new_build, :new_associated_build)
  end
end

json.url notifiers_api_v1_user_path(:json)