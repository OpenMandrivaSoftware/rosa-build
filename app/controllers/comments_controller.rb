class CommentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :set_commentable, :only => [:index, :edit, :create]
  before_filter :find_project, :only => [:index]
  before_filter :find_comment, :only => [:show, :edit, :update, :destroy]

  authorize_resource :only => [:show, :edit, :update, :destroy]
  authorize_resource :project, :only => [:index]

  def index
    @comments = @commentable.comments
  end

  def create
    @comment = @commentable.comments.build(params[:comment])
    @comment.user = current_user
    if @comment.save
      flash[:notice] = I18n.t("flash.comment.saved")
      redirect_to :back
    else
      flash[:error] = I18n.t("flash.comment.saved_error")
      render :action => 'new'
    end
  end

  def edit
    @issue = @commentable
    @project = @issue.project
  end

  def update
    if @comment.update_attributes(params[:comment])
      flash[:notice] = I18n.t("flash.comment.saved")
      #redirect_to :back
      redirect_to show_issue_path(@comment.commentable.project, @comment.commentable.serial_id)
    else
      flash[:error] = I18n.t("flash.comment.saved_error")
      render :action => 'new'
    end
  end

  def destroy
    @comment.destroy

    flash[:notice] = t("flash.comment.destroyed")
    redirect_to :back
  end

  private

  def find_commentable
    #params.each do |name, value|
    #  if name =~ /(.+)_id$/
    #    return $1.classify.constantize.find(value)
    #  end
    #end
    #nil
    return Issue.find(params[:issue_id])
  end

  def set_commentable
    @commentable = find_commentable
  end

  def find_comment
    @comment = Comment.find(params[:id])
  end

  def find_project
    @project = @comment.commentable.project
  end
end
