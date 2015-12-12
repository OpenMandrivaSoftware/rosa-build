class AddGithubOrganizationToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :github_organization, :string
  end
end
