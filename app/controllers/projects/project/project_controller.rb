class Projects::Project::ProjectController < Projects::Project::BaseController
  def index
    (render :error_github) if not @project.github_data
  end

  def commit
    redirect_to 'https://github.com/' + @project.github_get_organization + '/' + @project.name + '/commit/' + params[:sha]
  end

  def diff
	redirect_to 'https://github.com/' + @project.github_get_organization + '/' + @project.name + '/commit/' + params[:diff]
  end
end