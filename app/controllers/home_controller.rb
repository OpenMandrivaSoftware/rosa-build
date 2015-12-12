class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:root]
  skip_after_action :verify_authorized

  def root
    respond_to do |format|
      format.html { render 'pages/tour/abf-tour-project-description-1' }
    end
  end

  def activity(is_my_activity = false)
    @filter = t('feed_menu').has_key?(params[:filter].try(:to_sym)) ? params[:filter].to_sym : :all
    @activity_feeds = current_user.activity_feeds
                                  .by_project_name(params[:project_name_filter])
                                  .by_owner_uname(params[:owner_filter])
    @activity_feeds = @activity_feeds.where(kind: "ActivityFeed::#{@filter.upcase}".constantize) unless @filter == :all
    @activity_feeds = @activity_feeds.where(user_id: current_user) if @own_filter == :created
    @activity_feeds = @activity_feeds.where.not(user_id: current_user) if @own_filter == :not_created

    @activity_feeds = if is_my_activity
                        @activity_feeds.where(creator_id: current_user)
                      else
                        @activity_feeds.where.not(creator_id: current_user)
                      end

    @activity_feeds = @activity_feeds.paginate page: current_page

    respond_to do |format|
      format.html { render 'activity' }
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
