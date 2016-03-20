module GitHelper
  def versions_for_group_select(project)
    return [] unless project
    [
      [I18n.t('layout.git.repositories.branches'), project.github_branches.map(&:name).sort], 
      [I18n.t('layout.git.repositories.tags'), project.github_tags.map(&:name).sort]
    ]
  end
end
