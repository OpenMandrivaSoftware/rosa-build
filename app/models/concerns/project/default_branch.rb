# Internal: various definitions and instance methods related to default_branch.
#
# This module gets mixed in into Project class.
module Project::DefaultBranch
  extend ActiveSupport::Concern

  include DefaultBranchable

  ######################################
  #          Instance methods          #
  ######################################

  # Public: Get default branch according to owner configs.
  #
  # Returns found String branch name.

  def resolve_default_branch
    default_branch == 'master' ? owner.default_branch : default_branch
  end

  # Public: Finds branch name for platforms.
  #
  # save_to_platform   - The save Platform.
  # build_for_platform - The build Platform.
  #
  # Returns found String branch name.
  def project_version_for(save_to_platform, build_for_platform)
    return save_to_platform.default_branch if save_to_platform.name != build_for_platform.name
    build_for_platform.default_branch
  end
end
