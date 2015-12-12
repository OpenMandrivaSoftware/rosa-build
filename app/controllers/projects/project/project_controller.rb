class Projects::Project::ProjectController < Projects::Project::BaseController
  def index
    authorize @project
    (render :error_github) if not @project.github_data
  end
end