class CreateContainers < ActiveRecord::Migration
  def change
    create_table :containers do |t|
      t.string :name
      t.references :platform, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
