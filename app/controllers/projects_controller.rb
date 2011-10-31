class ProjectsController < ApplicationController
  before_filter :authenticate_user!, :except => :auto_build
  before_filter :find_project, :only => [:show, :edit, :update, :destroy, :build, :process_build]
  before_filter :get_paths, :only => [:new, :create, :edit, :update]
  before_filter :check_global_access, :except => :auto_build

  def index
    @projects = Project.visible_to(current_user).paginate(:page => params[:project_page])
  end

  def show
    @current_build_lists = @project.build_lists.current.recent.paginate :page => params[:page]
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new params[:project]
    @project.owner = get_owner

    if @project.save
      flash[:notice] = t('flash.project.saved') 
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      flash[:warning] = @project.errors[:base]
      render :action => :new
    end
  end

  def update
    if @project.update_attributes(params[:project])
      flash[:notice] = t('flash.project.saved')
      redirect_to @project
    else
      flash[:error] = t('flash.project.save_error')
      render :action => :edit
    end
  end

  def destroy
    @project.destroy
    flash[:notice] = t("flash.project.destroyed")
    redirect_to @project.owner
  end

  def auto_build    
    unixname = params[:git_repo].split('/')[1]
    project = Project.find_by_unixname(unixname)
    auto_build_list = AutoBuildList.find_by_project_id(project.id)

    p = params.delete_if{|k,v| k == 'controller' or k == 'action'}
    ActiveSupport::Notifications.instrument("event_log.observer", :object => project, :message => p.inspect)
    # logger.info "Git hook recieved from #{params[:git_user]} to #{params[:git_repo]}"

    BuildList.create!(
      :project_id => project.id, 
      :pl_id => auto_build_list.pl_id, 
      :bpl_id => auto_build_list.bpl_id, 
      :arch_id => auto_build_list.arch_id,
      :project_version => project.collected_project_versions.last.try(:first),
      :build_requires => true,
      :update_type => 'bugfix') if auto_build_list 
    
    render :nothing => true
  end

  def build
    @arches = Arch.recent
    @bpls = Platform.main
    @pls = @project.repositories.collect { |rep| ["#{rep.platform.name}/#{rep.unixname}", rep.platform.id] }
    @project_versions = @project.collected_project_versions
  end

  def process_build
    @arch_ids = params[:build][:arches].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    @arches = Arch.where(:id => @arch_ids)

    @project_version = params[:build][:project_version]

    bpls_ids = params[:build][:bpl].blank? ? [] : params[:build][:bpl].select{|_,v| v == "1"}.collect{|x| x[0].to_i }
    bpls = Platform.where(:id => bpls_ids)
    
    pl = Platform.find params[:build][:pl]
    update_type = params[:build][:update_type]
    build_requires = params[:build][:build_requires]

    @project_versions = @project.collected_project_versions

    if !check_arches || !check_project_versions
      @arches = Arch.recent
      @bpls = Platform.main
      @pls = @project.repositories.collect { |rep| ["#{rep.platform.name}/#{rep.unixname}", rep.platform.id] }
       
      render :action => "build"
    else
      flash[:notice], flash[:error] = "", ""
      @arches.each do |arch|
        bpls.each do |bpl|
          build_list = @project.build_lists.new(:arch => arch, :project_version => @project_version, :pl => pl, :bpl => bpl, :update_type =>  update_type, :build_requires => build_requires)
        
          if build_list.save
            flash[:notice] += t("flash.build_list.saved", :project_version => @project_version, :arch => arch.name, :bpl => bpl.name, :pl => pl)
          else
            flash[:error] += t("flash.build_list.save_error", :project_version => @project_version, :arch => arch.name, :bpl => bpl.name, :pl => pl)
          end
        end
      end

      redirect_to project_path(@project)
    end
  end

  protected

    def get_paths
      if params[:user_id]
        @user = User.find params[:user_id]
        @projects_path = user_path(@user) # user_projects_path @user
        @new_project_path = new_user_project_path @user
      elsif params[:group_id]
        @group = Group.find params[:group_id]
        @projects_path = group_path(@group) # group_projects_path @group
        @new_projects_path = new_group_project_path @group
      else
        @projects_path = projects_path
        @new_projects_path = new_project_path
      end
    end

    def find_project
      @project = Project.find params[:id]
    end

    def check_arches
      if @arch_ids.blank?
        flash[:error] = t("flash.build_list.no_arch_selected")
        false
      elsif @arch_ids.length != @arches.length
        flash[:error] = t("flash.build_list.no_arch_found")
        false
      else
        true
      end
    end

    def check_project_versions
      if @project_version.blank?
        flash[:error] = t("flash.build_list.no_project_version_selected")
        false
      elsif !@project_versions.flatten.include?(@project_version)
        flash[:error] = t("flash.build_list.no_project_version_found", :project_version => @project_version)
        false
      else
        true
      end
    end
end
