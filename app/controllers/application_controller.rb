class ApplicationController < ActionController::Base
  include StrongParams
  include Pundit

  AIRBRAKE_IGNORE = [
    ActionController::InvalidAuthenticityToken,
    AbstractController::ActionNotFound
  ]

  protect_from_forgery with: :exception

  layout :layout_by_resource

  # Hack to prevent token auth on all pages except atom feed:
  prepend_before_action -> { redirect_to(new_user_session_path) if params[:token] && params[:token].is_a?(String) && params[:format] != 'atom'}

  before_action :set_locale
  before_action -> { EventLog.current_controller = self },
                only: [:create, :destroy, :open_id, :cancel, :publish, :change_visibility] # :update
  before_action :banned?
  after_action -> { EventLog.current_controller = nil }
  after_action      :verify_authorized, unless: :devise_controller?
  skip_after_action :verify_authorized, only: %i(render_500 render_404)

  helper_method :get_owner

  unless Rails.env.development?
    rescue_from Exception, with: :render_500
    rescue_from ActiveRecord::RecordNotFound,
                # ActionController::RoutingError, # see: config/routes.rb:<last line>
                ActionController::UnknownController,
                ActionController::UnknownFormat,
                AbstractController::ActionNotFound, with: :render_404
  end

  rescue_from Pundit::NotAuthorizedError do |exception|
    redirect_to forbidden_url, alert: t("flash.exception_message")
  end


  def render_404
    render_error 404
  end

  protected

  # Disables access to site for banned users
  def banned?
    if user_signed_in? && current_user.access_locked?
      sign_out current_user
      flash[:error] = I18n.t('devise.failure.locked')
      redirect_to root_path
    end
  end

  def render_500(e)
    Raven.capture_exception(e)
    render_error 500
  end

  def render_error(status)
    respond_to do |format|
      format.json { render json: {status: status, message: t("flash.#{status}_message")}.to_json, status: status }
      format.all  { render file: "public/#{status}.html", status: status,
                           alert: t("flash.#{status}_message"), layout: false, content_type: 'text/html' }
    end
  end

  # Helper method for all controllers
  def permit_params(param_name, *accessible)
    (params[param_name] || ActionController::Parameters.new).permit(*accessible.flatten)
  end

  def set_locale
    I18n.locale = check_locale( get_user_locale ||
      (request.env['HTTP_ACCEPT_LANGUAGE'] ? request.env['HTTP_ACCEPT_LANGUAGE'][0,2].downcase : nil ))
  end

  def get_user_locale
    user_signed_in? ? current_user.language : nil
  end

  def check_locale(locale)
    User::LANGUAGES.include?(locale.to_s) ? locale : :en
  end

  def get_owner
    if self.class.method_defined? :parent
      if parent and (parent.is_a? User or parent.is_a? Group)
        return parent
      else
       return current_user
      end
    else
      params['user_id'] && User.find(params['user_id']) ||
      params['group_id'] && Group.find(params['group_id']) || current_user
    end
  end

  def layout_by_resource
    if devise_controller?
      "sessions"
    else
      "application"
    end
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def current_page
    params[:page] = 1 if params[:page].to_i < 1

    params[:page]
  end
end
