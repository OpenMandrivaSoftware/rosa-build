class AddEnable32BitToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :enable_32bit, :bool, default: false
  end
end
