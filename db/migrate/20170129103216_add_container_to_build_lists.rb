class AddContainerToBuildLists < ActiveRecord::Migration
  def change
    add_reference :build_lists, :container, index: true, foreign_key: true
  end
end
