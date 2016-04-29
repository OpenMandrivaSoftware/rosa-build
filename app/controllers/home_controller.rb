class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:root]
  skip_after_action :verify_authorized

  def index
    redirect_to projects_dashboard_path
  end

  def activity(is_my_activity = false)
    @activity_feeds = current_user.activity_feeds
                                  .by_project_name(params[:project_name_filter])
                                  .by_owner_uname(params[:owner_filter])

    @activity_feeds = if is_my_activity
                        @activity_feeds.where(creator_id: current_user)
                      else
                        @activity_feeds.where.not(creator_id: current_user)
                      end

    @activity_feeds = @activity_feeds.paginate page: current_page

    if @activity_feeds.next_page
      if is_my_activity
        method = :own_activity_path
      else
        method = :activity_feeds_path
      end
      @next_page_link = method.to_proc.call(self, page: @activity_feeds.next_page, owner_filter: params[:owner_filter],
                                                  project_name_filter: params[:project_name_filter], format: :json)
    end

    respond_to do |format|
      format.json { render 'activity' }
      format.atom
    end
  end

  def own_activity
    activity(true)
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
