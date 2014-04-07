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

ActiveRecord::Schema.define(version: 20140407140233) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id"

  create_table "data_imports", force: true do |t|
    t.integer  "user_id",                        null: false
    t.text     "status",                         null: false
    t.integer  "total_feeds",     default: 0,    null: false
    t.integer  "processed_feeds", default: 0,    null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "show_alert",      default: true, null: false
  end

  create_table "entries", force: true do |t|
    t.text     "title",                       null: false
    t.text     "url",                         null: false
    t.text     "author"
    t.text     "content",    limit: 16777215
    t.text     "summary",    limit: 16777215
    t.datetime "published",                   null: false
    t.text     "guid",                        null: false
    t.integer  "feed_id",                     null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "entry_states", force: true do |t|
    t.boolean  "read",       default: false, null: false
    t.integer  "user_id",                    null: false
    t.integer  "entry_id",                   null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "feed_subscriptions", force: true do |t|
    t.integer  "user_id",                    null: false
    t.integer  "feed_id",                    null: false
    t.integer  "unread_entries", default: 0, null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  create_table "feeds", force: true do |t|
    t.text     "title",                              null: false
    t.text     "url"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.text     "fetch_url",                          null: false
    t.text     "etag"
    t.text     "last_modified"
    t.datetime "last_fetched"
    t.integer  "fetch_interval_secs", default: 3600, null: false
    t.datetime "failing_since"
    t.boolean  "available",           default: true, null: false
  end

  create_table "feeds_folders", force: true do |t|
    t.integer "feed_id",   null: false
    t.integer "folder_id", null: false
  end

  create_table "folders", force: true do |t|
    t.integer  "user_id",    null: false
    t.text     "title",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "refresh_feed_job_states", force: true do |t|
    t.integer  "user_id",    null: false
    t.integer  "feed_id",    null: false
    t.text     "status",     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "admin",                  default: false, null: false
    t.text     "locale",                                 null: false
    t.text     "timezone",                               null: false
    t.boolean  "quick_reading",          default: false, null: false
    t.boolean  "open_all_entries",       default: false, null: false
    t.text     "name",                                   null: false
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true

end
