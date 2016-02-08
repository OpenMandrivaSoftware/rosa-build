class AddHostnameToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :hostname, :string
  end
end
