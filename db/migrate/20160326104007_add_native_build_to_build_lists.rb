class AddNativeBuildToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :native_build, :boolean, default: false
  end
end
