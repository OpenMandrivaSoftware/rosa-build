# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190210140249) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "arches", force: :cascade do |t|
    t.string   "name",       :null=>false, :index=>{:name=>"index_arches_on_name", :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authentications", force: :cascade do |t|
    t.integer  "user_id",    :index=>{:name=>"index_authentications_on_user_id"}
    t.string   "provider",   :index=>{:name=>"index_authentications_on_provider_and_uid", :with=>["uid"], :unique=>true}
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "build_list_items", force: :cascade do |t|
    t.string   "name"
    t.integer  "level"
    t.integer  "status"
    t.integer  "build_list_id", :index=>{:name=>"index_build_list_items_on_build_list_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version"
  end

  create_table "build_list_packages", force: :cascade do |t|
    t.integer  "build_list_id",      :index=>{:name=>"index_build_list_packages_on_build_list_id"}
    t.integer  "project_id",         :index=>{:name=>"index_build_list_packages_on_project_id"}
    t.integer  "platform_id",        :index=>{:name=>"index_build_list_packages_on_platform_id"}
    t.string   "fullname"
    t.string   "name",               :index=>{:name=>"index_build_list_packages_on_name_and_project_id", :with=>["project_id"]}
    t.string   "version"
    t.string   "release"
    t.string   "package_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "actual",             :default=>false, :index=>{:name=>"index_build_list_packages_on_actual_and_platform_id", :with=>["platform_id"]}
    t.string   "sha1"
    t.integer  "epoch"
    t.text     "dependent_packages"
    t.index :name=>"build_list_packages_ordering", :expression=>"lower((name)::text), length((name)::text)"
  end

  create_table "build_lists", force: :cascade do |t|
    t.integer  "status"
    t.string   "project_version"
    t.integer  "project_id",                    :index=>{:name=>"index_build_lists_on_project_id"}
    t.integer  "arch_id",                       :index=>{:name=>"index_build_lists_on_arch_id"}
    t.datetime "notified_at"
    t.datetime "created_at"
    t.datetime "updated_at",                    :index=>{:name=>"index_build_lists_on_updated_at", :order=>{"updated_at"=>:desc}}
    t.boolean  "is_circle",                     :default=>false
    t.text     "additional_repos"
    t.string   "name"
    t.string   "update_type"
    t.integer  "build_for_platform_id"
    t.integer  "save_to_platform_id"
    t.text     "include_repos"
    t.integer  "user_id",                       :index=>{:name=>"index_build_lists_on_user_id"}
    t.string   "package_version"
    t.string   "commit_hash"
    t.integer  "priority",                      :default=>0, :null=>false
    t.datetime "started_at"
    t.integer  "duration"
    t.integer  "mass_build_id",                 :index=>{:name=>"index_build_lists_on_mass_build_id_and_status", :with=>["status"]}
    t.integer  "save_to_repository_id"
    t.text     "results"
    t.boolean  "new_core",                      :default=>true
    t.string   "last_published_commit_hash"
    t.integer  "container_status"
    t.boolean  "auto_create_container",         :default=>false
    t.text     "extra_repositories"
    t.text     "extra_build_lists"
    t.integer  "publisher_id"
    t.integer  "group_id"
    t.text     "extra_params"
    t.string   "external_nodes"
    t.integer  "builder_id"
    t.boolean  "include_testing_subrepository"
    t.string   "auto_publish_status",           :default=>"default", :null=>false
    t.boolean  "use_cached_chroot",             :default=>false, :null=>false
    t.boolean  "use_extra_tests",               :default=>true, :null=>false
    t.boolean  "save_buildroot",                :default=>false, :null=>false
    t.string   "hostname"
    t.string   "fail_reason"
    t.boolean  "native_build",                  :default=>false
  end
  add_index "build_lists", ["project_id", "save_to_repository_id", "build_for_platform_id", "arch_id"], :name=>"maintainer_search_index"

  create_table "event_logs", force: :cascade do |t|
    t.integer  "user_id",        :index=>{:name=>"index_event_logs_on_user_id"}
    t.string   "user_name"
    t.integer  "eventable_id"
    t.string   "eventable_type", :index=>{:name=>"index_event_logs_on_eventable_type_and_eventable_id", :with=>["eventable_id"]}
    t.string   "eventable_name"
    t.string   "ip"
    t.string   "kind"
    t.string   "protocol"
    t.string   "controller"
    t.string   "action"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "flash_notifies", force: :cascade do |t|
    t.text     "body_ru",    :null=>false
    t.text     "body_en",    :null=>false
    t.string   "status",     :null=>false
    t.boolean  "published",  :default=>true, :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", force: :cascade do |t|
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname"
    t.integer  "own_projects_count",  :default=>0, :null=>false
    t.text     "description"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.string   "default_branch"
  end

  create_table "key_pairs", force: :cascade do |t|
    t.text     "public",           :null=>false
    t.text     "encrypted_secret", :null=>false
    t.string   "key_id",           :null=>false
    t.integer  "user_id",          :null=>false
    t.integer  "repository_id",    :null=>false, :index=>{:name=>"index_key_pairs_on_repository_id", :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "key_pairs_backup", force: :cascade do |t|
    t.integer  "repository_id", :null=>false, :index=>{:name=>"index_key_pairs_backup_on_repository_id", :unique=>true}
    t.integer  "user_id",       :null=>false
    t.string   "key_id",        :null=>false
    t.text     "public",        :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mass_builds", force: :cascade do |t|
    t.integer  "build_for_platform_id",         :null=>false
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "arch_names"
    t.integer  "user_id"
    t.integer  "build_lists_count",             :default=>0, :null=>false
    t.boolean  "stop_build",                    :default=>false, :null=>false
    t.text     "projects_list"
    t.integer  "missed_projects_count",         :default=>0, :null=>false
    t.text     "missed_projects_list"
    t.boolean  "new_core",                      :default=>true
    t.integer  "save_to_platform_id",           :null=>false
    t.text     "extra_repositories"
    t.text     "extra_build_lists"
    t.boolean  "increase_release_tag",          :default=>false, :null=>false
    t.boolean  "use_cached_chroot",             :default=>true, :null=>false
    t.boolean  "use_extra_tests",               :default=>false, :null=>false
    t.string   "description"
    t.string   "auto_publish_status",           :default=>"none", :null=>false
    t.text     "extra_mass_builds"
    t.boolean  "include_testing_subrepository", :default=>false, :null=>false
    t.boolean  "auto_create_container",         :default=>false, :null=>false
    t.integer  "status",                        :default=>2000, :null=>false
    t.string   "external_nodes"
  end

  create_table "platform_arch_settings", force: :cascade do |t|
    t.integer  "platform_id", :null=>false, :index=>{:name=>"index_platform_arch_settings_on_platform_id_and_arch_id", :with=>["arch_id"], :unique=>true}
    t.integer  "arch_id",     :null=>false
    t.integer  "time_living", :null=>false
    t.boolean  "default"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "platforms", force: :cascade do |t|
    t.string   "description"
    t.string   "name",                            :null=>false, :index=>{:name=>"index_platforms_on_name", :unique=>true, :case_sensitive=>false}
    t.integer  "parent_platform_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "released",                        :default=>false, :null=>false
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",                      :default=>"open", :null=>false
    t.string   "platform_type",                   :default=>"main", :null=>false
    t.string   "distrib_type"
    t.integer  "status"
    t.datetime "last_regenerated_at"
    t.integer  "last_regenerated_status"
    t.string   "last_regenerated_log_sha1"
    t.string   "automatic_metadata_regeneration"
    t.string   "default_branch",                  :null=>false
  end

  create_table "product_build_lists", force: :cascade do |t|
    t.integer  "product_id",      :index=>{:name=>"index_product_build_lists_on_product_id"}
    t.integer  "status",          :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id"
    t.string   "project_version"
    t.string   "commit_hash"
    t.string   "params"
    t.string   "main_script"
    t.text     "results"
    t.integer  "arch_id"
    t.integer  "time_living"
    t.integer  "user_id"
    t.boolean  "not_delete",      :default=>false
    t.boolean  "autostarted",     :default=>false
  end

  create_table "products", force: :cascade do |t|
    t.string   "name",             :null=>false
    t.integer  "platform_id",      :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "project_id"
    t.string   "params"
    t.string   "main_script"
    t.integer  "time_living"
    t.integer  "autostart_status"
    t.string   "project_version"
  end

  create_table "project_imports", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "name",        :index=>{:name=>"index_project_imports_on_name_and_platform_id", :with=>["platform_id"], :unique=>true, :case_sensitive=>false}
    t.string   "version"
    t.datetime "file_mtime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "platform_id"
  end

  create_table "project_statistics", force: :cascade do |t|
    t.integer  "average_build_time", :default=>0, :null=>false
    t.integer  "build_count",        :default=>0, :null=>false
    t.integer  "arch_id",            :null=>false
    t.integer  "project_id",         :null=>false, :index=>{:name=>"index_project_statistics_on_project_id_and_arch_id", :with=>["arch_id"], :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_to_repositories", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "repository_id",     :index=>{:name=>"index_project_to_repositories_on_repository_id_and_project_id", :with=>["project_id"], :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.hstore   "autostart_options"
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name",                     :index=>{:name=>"index_projects_on_name_and_owner_id_and_owner_type", :with=>["owner_id", "owner_type"], :unique=>true, :case_sensitive=>false}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "visibility",               :default=>"open"
    t.string   "ancestry"
    t.string   "srpm_file_name"
    t.string   "srpm_content_type"
    t.integer  "srpm_file_size"
    t.datetime "srpm_updated_at"
    t.string   "default_branch",           :default=>"master"
    t.boolean  "is_package",               :default=>true, :null=>false
    t.integer  "maintainer_id"
    t.boolean  "publish_i686_into_x86_64", :default=>false
    t.string   "owner_uname",              :null=>false
    t.boolean  "architecture_dependent",   :default=>false, :null=>false
    t.integer  "autostart_status"
    t.integer  "alias_from_id",            :index=>{:name=>"index_projects_on_alias_from_id"}
    t.string   "github_organization"
  end

  create_table "relations", force: :cascade do |t|
    t.integer  "actor_id"
    t.string   "actor_type",  :index=>{:name=>"index_relations_on_actor_type_and_actor_id", :with=>["actor_id"]}
    t.integer  "target_id"
    t.string   "target_type", :index=>{:name=>"index_relations_on_target_type_and_target_id", :with=>["target_id"]}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "role"
  end

  create_table "repositories", force: :cascade do |t|
    t.string   "description",                     :null=>false
    t.integer  "platform_id",                     :null=>false, :index=>{:name=>"index_repositories_on_platform_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                            :null=>false
    t.boolean  "publish_without_qa",              :default=>true
    t.boolean  "synchronizing_publications",      :default=>false, :null=>false
    t.string   "publish_builds_only_from_branch"
  end

  create_table "repository_statuses", force: :cascade do |t|
    t.integer  "repository_id",             :null=>false, :index=>{:name=>"index_repository_statuses_on_repository_id_and_platform_id", :with=>["platform_id"], :unique=>true}
    t.integer  "platform_id",               :null=>false
    t.integer  "status",                    :default=>0
    t.datetime "last_regenerated_at"
    t.integer  "last_regenerated_status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "last_regenerated_log_sha1"
  end

  create_table "settings_notifiers", force: :cascade do |t|
    t.integer  "user_id",              :null=>false
    t.boolean  "can_notify",           :default=>true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "new_build",            :default=>true
    t.boolean  "new_associated_build", :default=>true
  end

  create_table "statistics", force: :cascade do |t|
    t.integer  "user_id",                 :null=>false, :index=>{:name=>"index_statistics_on_user_id"}
    t.string   "email",                   :null=>false
    t.integer  "project_id",              :null=>false, :index=>{:name=>"index_statistics_on_project_id"}
    t.string   "project_name_with_owner", :null=>false
    t.string   "key",                     :null=>false, :index=>{:name=>"index_statistics_on_key"}
    t.integer  "counter",                 :default=>0, :null=>false
    t.datetime "activity_at",             :null=>false, :index=>{:name=>"index_statistics_on_activity_at"}
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "statistics", ["key", "activity_at"], :name=>"index_statistics_on_key_and_activity_at"
  add_index "statistics", ["project_id", "key", "activity_at"], :name=>"index_statistics_on_project_id_and_key_and_activity_at"
  add_index "statistics", ["user_id", "key", "activity_at"], :name=>"index_statistics_on_user_id_and_key_and_activity_at"
  add_index "statistics", ["user_id", "project_id", "key", "activity_at"], :name=>"index_statistics_on_all_keys", :unique=>true

  create_table "tokens", force: :cascade do |t|
    t.integer  "subject_id",           :null=>false, :index=>{:name=>"index_tokens_on_subject_id_and_subject_type", :with=>["subject_type"]}
    t.string   "subject_type",         :null=>false
    t.integer  "creator_id",           :null=>false
    t.integer  "updater_id"
    t.string   "status",               :default=>"active"
    t.text     "description"
    t.string   "authentication_token", :null=>false, :index=>{:name=>"index_tokens_on_authentication_token", :unique=>true}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_builds_settings", force: :cascade do |t|
    t.integer "user_id",        :null=>false, :index=>{:name=>"index_user_builds_settings_on_user_id", :unique=>true}
    t.text    "platforms",      :default=>[], :null=>false, :array=>true
    t.string  "external_nodes"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email",                   :default=>"", :null=>false, :index=>{:name=>"index_users_on_email", :unique=>true}
    t.string   "encrypted_password",      :default=>"", :null=>false
    t.string   "reset_password_token",    :index=>{:name=>"index_users_on_reset_password_token", :unique=>true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uname",                   :index=>{:name=>"index_users_on_uname", :unique=>true}
    t.string   "role"
    t.string   "language",                :default=>"en"
    t.integer  "own_projects_count",      :default=>0, :null=>false
    t.string   "confirmation_token",      :index=>{:name=>"index_users_on_confirmation_token", :unique=>true}
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.text     "professional_experience"
    t.string   "site"
    t.string   "company"
    t.string   "location"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "failed_attempts",         :default=>0
    t.string   "unlock_token",            :index=>{:name=>"index_users_on_unlock_token", :unique=>true}
    t.datetime "locked_at"
    t.string   "authentication_token",    :index=>{:name=>"index_users_on_authentication_token"}
    t.integer  "build_priority",          :default=>50
    t.boolean  "sound_notifications",     :default=>true
    t.boolean  "hide_email",              :default=>true, :null=>false
  end

end
