class ApplicationController::Base

    def can_perform? target = :system
      c = self.controller_name
      a = self.action_name

      current_user.can_perform? c, a, target
    end

    def check_global_rights
      unless can_perform?
        flash[:notice] = t('layout.not_access')
        redirect_to(:back)
      end
    end

  class << self

    def rights_to target
      Rights.where :rtype => target.class.to_s
    end

  end
end