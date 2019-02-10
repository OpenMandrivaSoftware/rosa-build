class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:root]
  skip_after_action :verify_authorized

  def index
    redirect_to projects_path
  end

  def get_owners_list
    if params[:term].present?
      users   =  User.opened.search(params[:term]).first(5)
      groups  = Group.opened.search(params[:term]).first(5)
      @owners = users | groups

    end
    respond_to do |format|
      format.json {}
    end
  end

  def get_project_names_list
    if params[:term].present?
      @projects = ProjectPolicy::Scope.new(current_user, Project).membered

      @projects = @projects.where(owner_uname: params[:owner_uname]) if params[:owner_uname].present?
      @projects = @projects.by_name("%#{params[:term]}%")
                           .distinct
                           .pluck(:name)
                           .first(10)
    end
    respond_to do |format|
      format.json {}
    end
  end
end
