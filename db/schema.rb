# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_01_000010) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "children", force: :cascade do |t|
    t.datetime "archived_at"
    t.date "birthdate"
    t.string "color", default: "sky", null: false
    t.datetime "created_at", null: false
    t.string "emoji"
    t.integer "family_id", null: false
    t.string "name", null: false
    t.string "pin_digest"
    t.integer "points_balance", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["family_id", "archived_at"], name: "index_children_on_family_id_and_archived_at"
    t.index ["family_id", "position"], name: "index_children_on_family_id_and_position"
    t.index ["family_id"], name: "index_children_on_family_id"
  end

  create_table "dojo_behaviors", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "category", default: "positive", null: false
    t.string "color", default: "emerald", null: false
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.string "icon", default: "⭐", null: false
    t.string "name", null: false
    t.integer "points", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["family_id", "archived_at"], name: "index_dojo_behaviors_on_family_id_and_archived_at"
    t.index ["family_id", "category", "position"], name: "index_dojo_behaviors_on_family_category_position"
    t.index ["family_id"], name: "index_dojo_behaviors_on_family_id"
  end

  create_table "dojo_point_events", force: :cascade do |t|
    t.integer "behavior_id"
    t.integer "child_id", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.text "note"
    t.datetime "occurred_at", null: false
    t.integer "points", null: false
    t.integer "requested_points", null: false
    t.datetime "reverted_at"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["behavior_id"], name: "index_dojo_point_events_on_behavior_id"
    t.index ["child_id", "occurred_at"], name: "index_dojo_point_events_on_child_id_and_occurred_at"
    t.index ["child_id", "reverted_at"], name: "index_dojo_point_events_on_child_id_and_reverted_at"
    t.index ["child_id"], name: "index_dojo_point_events_on_child_id"
    t.index ["occurred_at"], name: "index_dojo_point_events_on_occurred_at"
    t.index ["user_id"], name: "index_dojo_point_events_on_user_id"
  end

  create_table "dojo_redemptions", force: :cascade do |t|
    t.integer "child_id", null: false
    t.integer "cost", null: false
    t.datetime "created_at", null: false
    t.datetime "decided_at"
    t.datetime "fulfilled_at"
    t.text "note"
    t.integer "reward_id", null: false
    t.string "status", default: "requested", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["child_id", "status"], name: "index_dojo_redemptions_on_child_id_and_status"
    t.index ["child_id"], name: "index_dojo_redemptions_on_child_id"
    t.index ["reward_id"], name: "index_dojo_redemptions_on_reward_id"
    t.index ["status"], name: "index_dojo_redemptions_on_status"
    t.index ["user_id"], name: "index_dojo_redemptions_on_user_id"
  end

  create_table "dojo_rewards", force: :cascade do |t|
    t.datetime "archived_at"
    t.integer "cost", null: false
    t.datetime "created_at", null: false
    t.integer "family_id", null: false
    t.string "icon", default: "🎁", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["family_id", "archived_at"], name: "index_dojo_rewards_on_family_id_and_archived_at"
    t.index ["family_id", "position"], name: "index_dojo_rewards_on_family_id_and_position"
    t.index ["family_id"], name: "index_dojo_rewards_on_family_id"
  end

  create_table "families", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.json "settings", default: {}, null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.integer "family_id", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "parent", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["family_id"], name: "index_users_on_family_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "children", "families"
  add_foreign_key "dojo_behaviors", "families"
  add_foreign_key "dojo_point_events", "children"
  add_foreign_key "dojo_point_events", "dojo_behaviors", column: "behavior_id"
  add_foreign_key "dojo_point_events", "users"
  add_foreign_key "dojo_redemptions", "children"
  add_foreign_key "dojo_redemptions", "dojo_rewards", column: "reward_id"
  add_foreign_key "dojo_redemptions", "users"
  add_foreign_key "dojo_rewards", "families"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "families"
end
