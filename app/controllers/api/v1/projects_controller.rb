class Api::V1::ProjectsController < Api::V1::BaseController

  before_action :authenticate_user!
  skip_before_action :check_auth, only: [:get_id, :show] if APP_CONFIG['anonymous_access']
  skip_before_action :authenticate_user!, only: [:get_id, :show] if APP_CONFIG['anonymous_access']

  before_action :load_project, except: [:index, :create, :get_id]

  def index
    authorize :project
    @projects = ProjectPolicy::Scope.new(current_user, Project).
      membered.paginate(paginate_params)
  end

  def get_id
    authorize @project = Project.find_by_owner_and_name!(params[:owner], params[:name])
  end

  def show
  end

  def update
    update_subject @project
  end

  def destroy
    destroy_subject @project
  end

  def create
    @project   = Project.new subject_params(Project)
    p_params   = params[:project] || {}
    owner_type = %w(User Group).find{ |t| t == p_params[:owner_type] }
    if owner_type.present?
      @project.owner = owner_type.constantize.find_by(id: p_params[:owner_id])
    else
      @project.owner = nil
    end
    authorize @project
    create_subject @project
  end

  def members
    @members = @project.collaborators.order('uname').paginate(paginate_params)
  end

  def add_member
    add_member_to_subject @project, params[:role]
  end

  def remove_member
    remove_member_from_subject @project
  end

  def update_member
    update_member_in_subject @project
  end

  private

  # Private: before_action hook which loads Project.
  def load_project
    authorize @project = Project.find(params[:id])
  end
end
