class RemoveUnusedColumns < ActiveRecord::Migration
  def change
    change_table :build_lists do |t|
      t.remove :advisory_id
    end

    change_table :projects do |t|
      t.remove :has_issues, :has_wiki, :description
    end

    change_table :settings_notifiers do |t|
      t.remove :new_comment, :new_comment_reply, :new_issue, :issue_assign, :new_comment_commit_owner,\
                :new_comment_commit_repo_owner, :new_comment_commit_commentor, :update_code
    end

    change_table :users do |t|
      t.remove :ssh_key
    end

    drop_table :advisories
    drop_join_table :advisories, :platforms
    drop_join_table :advisories, :projects
    drop_table :build_scripts
    drop_table :comments
    drop_table :hooks
    drop_table :issues
    drop_table :labelings
    drop_table :labels
    drop_table :node_instructions
    drop_table :project_tags
    drop_table :pull_requests
    drop_table :register_requests
    drop_table :ssh_keys
    drop_table :subscribes
  end
end
