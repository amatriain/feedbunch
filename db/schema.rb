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

ActiveRecord::Schema.define(version: 20150128162753) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "deleted_entries", force: :cascade do |t|
    t.integer  "feed_id",    null: false
    t.text     "guid",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "deleted_entries", ["guid", "feed_id"], name: "index_deleted_entries_on_guid_feed_id", using: :btree

  create_table "entries", force: :cascade do |t|
    t.text     "title",      null: false
    t.text     "url",        null: false
    t.text     "author"
    t.text     "content"
    t.text     "summary"
    t.datetime "published",  null: false
    t.text     "guid",       null: false
    t.integer  "feed_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "entries", ["feed_id"], name: "index_entries_on_feed_id", using: :btree
  add_index "entries", ["guid", "feed_id"], name: "index_entries_on_guid_feed_id", using: :btree
  add_index "entries", ["published", "created_at", "id"], name: "index_entries_on_published_created_at_id", order: {"published"=>:desc, "created_at"=>:desc, "id"=>:desc}, using: :btree

  create_table "entry_states", force: :cascade do |t|
    t.boolean  "read",       default: false, null: false
    t.integer  "user_id",                    null: false
    t.integer  "entry_id",                   null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "entry_states", ["entry_id", "user_id"], name: "index_entry_states_on_entry_id_user_id", using: :btree
  add_index "entry_states", ["entry_id"], name: "index_entry_states_on_entry_id", using: :btree
  add_index "entry_states", ["read", "user_id"], name: "index_entry_states_on_read_user_id", using: :btree
  add_index "entry_states", ["user_id"], name: "index_entry_states_on_user_id", using: :btree

  create_table "feed_subscriptions", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.integer  "feed_id",                    null: false
    t.integer  "unread_entries", default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "feed_subscriptions", ["feed_id", "user_id"], name: "index_feed_subscriptions_on_feed_id_user_id", using: :btree
  add_index "feed_subscriptions", ["feed_id"], name: "index_feed_subscriptions_on_feed_id", using: :btree
  add_index "feed_subscriptions", ["user_id", "unread_entries"], name: "index_feed_subscriptions_on_user_id_unread_entries", using: :btree
  add_index "feed_subscriptions", ["user_id"], name: "index_feed_subscriptions_on_user_id", using: :btree

  create_table "feeds", force: :cascade do |t|
    t.text     "title",                              null: false
    t.text     "url"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.text     "fetch_url",                          null: false
    t.datetime "last_fetched"
    t.integer  "fetch_interval_secs", default: 3600, null: false
    t.datetime "failing_since"
    t.boolean  "available",           default: true, null: false
  end

  add_index "feeds", ["available"], name: "index_feeds_on_available", using: :btree
  add_index "feeds", ["fetch_url"], name: "index_feeds_on_fetch_url", using: :btree
  add_index "feeds", ["title"], name: "index_feeds_on_title", using: :btree
  add_index "feeds", ["url"], name: "index_feeds_on_url", using: :btree

  create_table "feeds_folders", force: :cascade do |t|
    t.integer  "feed_id",    null: false
    t.integer  "folder_id",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "feeds_folders", ["feed_id"], name: "index_feeds_folders_on_feed_id", using: :btree
  add_index "feeds_folders", ["folder_id"], name: "index_feeds_folders_on_folder_id", using: :btree

  create_table "folders", force: :cascade do |t|
    t.integer  "user_id",            null: false
    t.text     "title",              null: false
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.text     "subscriptions_etag"
  end

  add_index "folders", ["user_id", "title"], name: "index_folders_on_user_id_title", using: :btree
  add_index "folders", ["user_id"], name: "index_folders_on_user_id", using: :btree

  create_table "opml_export_job_states", force: :cascade do |t|
    t.integer  "user_id",                    null: false
    t.text     "state",                      null: false
    t.boolean  "show_alert",  default: true, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.text     "filename"
    t.datetime "export_date"
  end

  add_index "opml_export_job_states", ["user_id"], name: "index_opml_export_job_states_on_user_id", using: :btree

  create_table "opml_import_failures", force: :cascade do |t|
    t.integer  "opml_import_job_state_id", null: false
    t.text     "url",                      null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "opml_import_failures", ["opml_import_job_state_id"], name: "index_opml_import_failures_on_job_state_id", using: :btree

  create_table "opml_import_job_states", force: :cascade do |t|
    t.integer  "user_id",                        null: false
    t.text     "state",                          null: false
    t.integer  "total_feeds",     default: 0,    null: false
    t.integer  "processed_feeds", default: 0,    null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "show_alert",      default: true, null: false
  end

  add_index "opml_import_job_states", ["user_id"], name: "index_opml_import_job_states_on_user_id", using: :btree

  create_table "refresh_feed_job_states", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "feed_id",    null: false
    t.text     "state",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "refresh_feed_job_states", ["created_at"], name: "index_refresh_feed_job_states_on_created_at", using: :btree
  add_index "refresh_feed_job_states", ["user_id"], name: "index_refresh_feed_job_states_on_user_id", using: :btree

  create_table "sidekiq_jobs", force: :cascade do |t|
    t.string   "jid"
    t.string   "queue"
    t.string   "class_name"
    t.text     "args"
    t.boolean  "retry"
    t.datetime "enqueued_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string   "status"
    t.string   "name"
    t.text     "result"
  end

  add_index "sidekiq_jobs", ["class_name"], name: "index_sidekiq_jobs_on_class_name", using: :btree
  add_index "sidekiq_jobs", ["enqueued_at"], name: "index_sidekiq_jobs_on_enqueued_at", using: :btree
  add_index "sidekiq_jobs", ["finished_at"], name: "index_sidekiq_jobs_on_finished_at", using: :btree
  add_index "sidekiq_jobs", ["jid"], name: "index_sidekiq_jobs_on_jid", using: :btree
  add_index "sidekiq_jobs", ["queue"], name: "index_sidekiq_jobs_on_queue", using: :btree
  add_index "sidekiq_jobs", ["retry"], name: "index_sidekiq_jobs_on_retry", using: :btree
  add_index "sidekiq_jobs", ["started_at"], name: "index_sidekiq_jobs_on_started_at", using: :btree
  add_index "sidekiq_jobs", ["status"], name: "index_sidekiq_jobs_on_status", using: :btree

  create_table "subscribe_job_states", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.text     "state",      null: false
    t.text     "fetch_url",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "feed_id"
  end

  add_index "subscribe_job_states", ["created_at"], name: "index_subscribe_job_states_on_created_at", using: :btree
  add_index "subscribe_job_states", ["user_id"], name: "index_subscribe_job_states_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                        default: "",    null: false
    t.string   "encrypted_password",           default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",              default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.boolean  "admin",                        default: false, null: false
    t.text     "locale",                                       null: false
    t.text     "timezone",                                     null: false
    t.boolean  "quick_reading",                default: false, null: false
    t.boolean  "open_all_entries",             default: false, null: false
    t.text     "name",                                         null: false
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",            default: 0
    t.string   "unencrypted_invitation_token"
    t.datetime "invitations_count_reset_at"
    t.boolean  "show_main_tour",               default: true,  null: false
    t.boolean  "show_mobile_tour",             default: true,  null: false
    t.boolean  "show_feed_tour",               default: true,  null: false
    t.boolean  "show_entry_tour",              default: true,  null: false
    t.datetime "folders_updated_at"
    t.datetime "config_updated_at"
    t.datetime "user_data_updated_at"
    t.text     "subscribe_jobs_etag"
    t.text     "refresh_feed_jobs_etag"
    t.text     "subscriptions_etag"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["confirmed_at", "confirmation_sent_at"], name: "index_users_on_confirmation_fields", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_limit"], name: "index_users_on_invitation_limit", using: :btree
  add_index "users", ["invitation_token", "invitation_accepted_at", "invitation_sent_at"], name: "index_users_on_invitation_fields", using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invitations_count", "invitations_count_reset_at"], name: "index_users_on_invitation_count_fields", using: :btree
  add_index "users", ["invitations_count"], name: "index_users_on_invitations_count", using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  add_foreign_key "deleted_entries", "feeds"
  add_foreign_key "entries", "feeds"
  add_foreign_key "entry_states", "entries"
  add_foreign_key "entry_states", "users"
  add_foreign_key "feed_subscriptions", "feeds"
  add_foreign_key "feed_subscriptions", "users"
  add_foreign_key "feeds_folders", "feeds"
  add_foreign_key "feeds_folders", "folders"
  add_foreign_key "folders", "users"
  add_foreign_key "opml_export_job_states", "users"
  add_foreign_key "opml_import_failures", "opml_import_job_states"
  add_foreign_key "opml_import_job_states", "users"
  add_foreign_key "refresh_feed_job_states", "feeds"
  add_foreign_key "refresh_feed_job_states", "users"
  add_foreign_key "subscribe_job_states", "users"
end
