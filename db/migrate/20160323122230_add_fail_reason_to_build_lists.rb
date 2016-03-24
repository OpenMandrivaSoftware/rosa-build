class AddFailReasonToBuildLists < ActiveRecord::Migration
  def change
    add_column :build_lists, :fail_reason, :string
  end
end
