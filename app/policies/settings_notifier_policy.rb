class SettingsNotifierPolicy < ApplicationPolicy

  # Public: Get list of parameters that the user is allowed to alter.
  #
  # Returns Array
  def permitted_attributes
    %i(
      can_notify
      new_build
      new_associated_build
    )
  end

end
