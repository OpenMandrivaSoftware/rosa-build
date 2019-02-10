class DestroyActivityFeeds < ActiveRecord::Migration
  def change
    drop_table :activity_feeds
  end
end
