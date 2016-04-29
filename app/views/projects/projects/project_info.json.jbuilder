json.project_info do |proj|
  proj.(@github_basic_info, :html_url, :description)

  proj.commits @commits do |commit|
    proj.(commit, :branch, :url, :sha, :message, :committer_login, :committer_url)
  end
end