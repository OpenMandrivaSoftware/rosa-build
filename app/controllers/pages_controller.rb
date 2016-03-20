class PagesController < ApplicationController
  skip_after_action :verify_authorized

  def forbidden
  end

  def tos
  end

end
