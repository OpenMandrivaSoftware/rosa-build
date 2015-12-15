class Projects::Project::ProjectController < Projects::Project::BaseController
  def index
    (render :error_github) if not @project.github_data
  end

  def commit
    redirect_to @project.github_data.html_url + "/commit/" + params[:sha]
  end
end