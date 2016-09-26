class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def github
    oauthorize 'GitHub'
  end

  def passthru
    render file: "#{Rails.root}/public/404.html", status: 404, layout: false
  end

  private

  def oauthorize(kind)
    provider = kind.downcase
    @user = find_for_ouath(env["omniauth.auth"], current_user)
    if @user && @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: action_name.classify
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.#{provider}_data"] = env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def find_for_ouath(auth, resource=nil)
    provider, uid   = auth['provider'], auth['uid']
    authentication  = Authentication.find_or_initialize_by(provider: provider, uid: uid)
    if authentication.new_record?
      if user_signed_in? # New authentication method for current_user
        authentication.user = current_user
      else # Register new user from session
        case provider
        when 'github'
          name = auth['info']['nickname'] || auth['info']['name']
        else
          raise ActiveRecord::RecordNotFound
        end
        user = User.find_or_initialize_by email: auth['info']['email']
        if user.new_record?
          user.name     = name
          user.uname    = name.gsub(/\s/, '').underscore
          user.password = Devise.friendly_token[0,20]
          user.confirmed_at = Time.zone.now
          user.save
        end
        authentication.user = user
      end
      authentication.save
    end
    return authentication.user
  end

end
