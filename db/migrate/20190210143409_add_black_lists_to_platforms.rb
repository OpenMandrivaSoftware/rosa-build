class AddBlackListsToPlatforms < ActiveRecord::Migration
  def change
    add_column :platforms, :project_list, :string, default: ''
    add_column :platforms, :project_list_type, :integer, default: 0
    add_column :platforms, :project_list_active, :boolean, default: false
  end
end
