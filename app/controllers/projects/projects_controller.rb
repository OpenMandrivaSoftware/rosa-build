class Projects::ProjectsController < Projects::BaseController
  include DatatableHelper
  include ProjectsHelper

  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:commit, :diff]
  before_action :who_owns, only: [:new, :create, :mass_import, :run_mass_import]

  def index
    authorize :project
    respond_to do |format|
      format.html
      format.json {
        if not params[:search].present?
          @projects = Project.find(current_user.build_lists.group(:project_id).limit(10).pluck(:project_id))
        else
          @projects = ProjectPolicy::Scope.new(current_user, Project).membered.search(params[:search]).limit(20)
        end
      }
    end
  end

  def project_info
    authorize @project
    respond_to do |format|
      format.json {
        @github_basic_info = @project.github_data
        @commits = []
        @project.github_branches.each do |branch|
          last_commit_info = @project.github_last_commit(branch.name)[0]
          if last_commit_info
            last_commit = {
                          branch: branch.name,
                          url: last_commit_info['html_url'],
                          sha: last_commit_info['sha'],
                          message: last_commit_info['commit']['message']
                        }
            if last_commit_info['committer']
              last_commit[:committer_login] = last_commit_info['committer']['login']
              last_commit[:committer_url] = last_commit_info['committer']['html_url']
            else
              last_commit[:committer_login] = last_commit_info['commit']['author']['name']
              last_commit[:committer_url] = ''
            end
            @commits << last_commit
          end
        end
      }
    end
  end

  def dashboard
    authorize :project
  end

  def new
    authorize :project
    @project = Project.new
  end

  def edit
    authorize @project
  end

  def create
    @project = Project.new project_params
    @project.owner = choose_owner
    authorize @project

    if @project.save
      flash[:notice] = t('flash.project.saved')
      redirect_to project_build_lists_path(@project)
    else
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors.full_messages.join('. ')
      render action: :new
    end
  end

  def update
    authorize @project
    params[:project].delete(:maintainer_id) if params[:project][:maintainer_id].blank?
    respond_to do |format|
      format.html do
        if @project.update_attributes(project_params)
          flash[:notice] = t('flash.project.saved')
          redirect_to root_path
        else
          flash[:error] = t('flash.project.save_error')
          flash[:warning] = @project.errors.full_messages.join('. ')
          render action: :edit
        end
      end
      format.json do
        if @project.update_attributes(project_params)
          render json: { notice: I18n.t('flash.project.saved') }
        else
          render json: { error: I18n.t('flash.project.save_error') }, status: 422
        end
      end
    end
  end

  def schedule
    authorize @project
    p_to_r = @project.project_to_repositories.find_by(repository_id: params[:repository_id])
    unless p_to_r.repository.publish_without_qa
      authorize p_to_r.repository.platform, :local_admin_manage?
    end
    p_to_r.user_id      = current_user.id
    p_to_r.enabled      = params[:enabled].present?
    p_to_r.auto_publish = params[:auto_publish].present?
    p_to_r.save
    if p_to_r.save
      render json: { notice: I18n.t('flash.project.saved') }.to_json
    else
      render json: { error: I18n.t('flash.project.save_error') }.to_json, status: 422
    end
  end

  def destroy
    authorize @project
    @project.destroy
    flash[:notice] = t("flash.project.destroyed")
    redirect_to @project.owner
  end

  def autocomplete_maintainers
    authorize @project
    term, limit = params[:query], params[:limit] || 10
    items = User.member_of_project(@project)
                .where("users.name ILIKE ? OR users.uname ILIKE ?", "%#{term}%", "%#{term}%")
                .limit(limit).map { |u| {name: u.fullname, id: u.id} }
    render json: items
  end

  def commit
    redirect_to 'https://github.com/' + @project.github_get_organization + '/' + @project.name + '/commit/' + params[:sha]
  end

  def diff
    redirect_to 'https://github.com/' + @project.github_get_organization + '/' + @project.name + '/compare/' + params[:diff]
  end

  protected

  def project_params
    subject_params(Project)
  end

  def who_owns
    @who_owns = (@project.try(:owner_type) == 'User' ? :me : :group)
  end

  def choose_owner
    if params[:who_owns] == 'group'
      Group.find(params[:owner_id])
    else
      current_user
    end
  end
end
