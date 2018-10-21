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

ActiveRecord::Schema.define(version: 2018_10_20_084829) do

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_id", null: false
    t.string "resource_type", null: false
    t.string "author_type"
    t.integer "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"
  end

  create_table "deleted_entries", force: :cascade do |t|
    t.integer "feed_id", null: false
    t.text "guid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guid", "feed_id"], name: "index_deleted_entries_on_guid_feed_id"
  end

  create_table "entries", force: :cascade do |t|
    t.text "title", null: false
    t.text "url", null: false
    t.text "author"
    t.text "content", limit: 16777215
    t.text "summary", limit: 16777215
    t.datetime "published", null: false
    t.text "guid", null: false
    t.integer "feed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id"], name: "index_entries_on_feed_id"
    t.index ["guid", "feed_id"], name: "index_entries_on_guid_feed_id"
    t.index ["published", "created_at", "id"], name: "index_entries_on_published_created_at_id"
  end

  create_table "entry_states", force: :cascade do |t|
    t.boolean "read", default: false, null: false
    t.integer "user_id", null: false
    t.integer "entry_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "published", null: false
    t.datetime "entry_created_at", null: false
    t.index ["entry_id", "user_id"], name: "index_entry_states_on_entry_id_user_id"
    t.index ["published", "entry_created_at", "entry_id", "user_id"], name: "index_entry_states_on_order_fields"
    t.index ["published", "entry_created_at", "entry_id", "user_id"], name: "index_entry_states_unread_on_order_fields", where: "read = 'false'"
    t.index ["read", "user_id"], name: "index_entry_states_on_read_user_id"
    t.index ["user_id"], name: "index_entry_states_on_user_id"
  end

  create_table "feed_subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "feed_id", null: false
    t.integer "unread_entries", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id", "user_id"], name: "index_feed_subscriptions_on_feed_id_user_id"
    t.index ["user_id", "unread_entries"], name: "index_feed_subscriptions_on_user_id_unread_entries"
  end

  create_table "feeds", force: :cascade do |t|
    t.text "title", null: false
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "fetch_url", null: false
    t.datetime "last_fetched"
    t.integer "fetch_interval_secs", default: 3600, null: false
    t.datetime "failing_since"
    t.boolean "available", default: true, null: false
    t.index ["available"], name: "index_feeds_on_available"
    t.index ["fetch_url"], name: "index_feeds_on_fetch_url"
    t.index ["title"], name: "index_feeds_on_title"
    t.index ["url"], name: "index_feeds_on_url"
  end

  create_table "feeds_folders", force: :cascade do |t|
    t.integer "feed_id", null: false
    t.integer "folder_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id"], name: "index_feeds_folders_on_feed_id"
    t.index ["folder_id"], name: "index_feeds_folders_on_folder_id"
  end

  create_table "folders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "subscriptions_updated_at"
    t.index ["user_id", "title"], name: "index_folders_on_user_id_title"
  end

  create_table "opml_export_job_states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "state", null: false
    t.boolean "show_alert", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "filename"
    t.datetime "export_date"
    t.index ["user_id"], name: "index_opml_export_job_states_on_user_id"
  end

  create_table "opml_import_failures", force: :cascade do |t|
    t.integer "opml_import_job_state_id", null: false
    t.text "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["opml_import_job_state_id"], name: "index_opml_import_failures_on_job_state_id"
  end

  create_table "opml_import_job_states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "state", null: false
    t.integer "total_feeds", default: 0, null: false
    t.integer "processed_feeds", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_alert", default: true, null: false
    t.index ["user_id"], name: "index_opml_import_job_states_on_user_id"
  end

  create_table "refresh_feed_job_states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "feed_id", null: false
    t.text "state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_refresh_feed_job_states_on_created_at"
    t.index ["user_id"], name: "index_refresh_feed_job_states_on_user_id"
  end

  create_table "subscribe_job_states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "state", null: false
    t.text "fetch_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "feed_id"
    t.index ["created_at"], name: "index_subscribe_job_states_on_created_at"
    t.index ["user_id"], name: "index_subscribe_job_states_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.text "locale", null: false
    t.text "timezone", null: false
    t.boolean "quick_reading", default: false, null: false
    t.boolean "open_all_entries", default: false, null: false
    t.text "name", null: false
    t.boolean "show_main_tour", default: true, null: false
    t.boolean "show_mobile_tour", default: true, null: false
    t.boolean "show_feed_tour", default: true, null: false
    t.boolean "show_entry_tour", default: true, null: false
    t.datetime "subscriptions_updated_at"
    t.datetime "folders_updated_at"
    t.datetime "subscribe_jobs_updated_at"
    t.datetime "refresh_feed_jobs_updated_at"
    t.datetime "config_updated_at"
    t.datetime "user_data_updated_at"
    t.boolean "free", default: false, null: false
    t.boolean "first_confirmation_reminder_sent", default: false, null: false
    t.boolean "second_confirmation_reminder_sent", default: false, null: false
    t.boolean "kb_shortcuts_enabled", default: true, null: false
    t.boolean "show_kb_shortcuts_tour", default: true, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["confirmed_at", "confirmation_sent_at", "first_confirmation_reminder_sent"], name: "index_users_on_first_reminder_fields"
    t.index ["confirmed_at", "confirmation_sent_at", "second_confirmation_reminder_sent"], name: "index_users_on_second_reminder_fields"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["first_confirmation_reminder_sent"], name: "index_users_on_first_invitation_reminder_fields"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["second_confirmation_reminder_sent"], name: "index_users_on_second_invitation_reminder_fields"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

end
