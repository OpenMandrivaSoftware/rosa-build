class PlatformsController < ApplicationController
  before_filter :authenticate_user!

  def index
    @platforms = Platform.all
  end

  def show
    @platform = Platform.find params[:id], :include => :repositories
    @repositories = @platform.repositories
  end

  def new
    @platforms = Platform.all
    @platform = Platform.new
  end

  def create
    @platform = Platform.new params[:platform]
    if @platform.save
      flash[:notice] = 'Платформа успешно добавлена'
      redirect_to @platform
    else
      flash[:error] = 'Не удалось создать платформу'
      render :action => :new
    end
  end

  def destroy
    Platform.destroy params[:id]
    redirect_to root_path
  end
end
