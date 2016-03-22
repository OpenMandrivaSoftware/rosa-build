class Projects::BaseController < ApplicationController
  prepend_before_action :find_project

  protected

  def find_project
    return if params[:name_with_owner].blank?
    authorize @project = Project.find_by_owner_and_name!(params[:name_with_owner]), :show?
  end
end
