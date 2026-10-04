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

ActiveRecord::Schema[7.0].define(version: 2026_10_04_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "max_site_size", default: 1
    t.integer "max_sites", default: 3
    t.string "plan_handle", default: "free"
    t.boolean "admin", default: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["plan_handle"], name: "index_accounts_on_plan_handle"
    t.index ["reset_password_token"], name: "index_accounts_on_reset_password_token", unique: true
  end

  create_table "domains", force: :cascade do |t|
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "site_id"
    t.index ["domain"], name: "index_domains_on_domain", unique: true
    t.index ["site_id"], name: "index_domains_on_site_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "plan_handle", null: false
    t.string "max_sites", null: false
    t.string "max_site_size", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price"
    t.index ["plan_handle"], name: "index_plans_on_plan_handle", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.boolean "published"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "site_dashboards", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.boolean "is_default", default: false, null: false
    t.jsonb "global_filters", default: {}, null: false
    t.jsonb "layout", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["site_id", "is_default"], name: "index_site_dashboards_on_site_id_and_is_default"
    t.index ["site_id", "slug"], name: "index_site_dashboards_on_site_id_and_slug", unique: true
    t.index ["site_id"], name: "index_site_dashboards_on_site_id"
  end

  create_table "site_file_versions", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "path", null: false
    t.text "content", null: false
    t.integer "byte_size", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["created_at"], name: "index_site_file_versions_on_created_at"
    t.index ["site_id", "path", "created_at"], name: "index_site_file_versions_on_site_path_created"
    t.index ["site_id"], name: "index_site_file_versions_on_site_id"
  end

  create_table "site_moment_files", force: :cascade do |t|
    t.bigint "site_moment_id", null: false
    t.string "path", null: false
    t.text "content", null: false
    t.integer "byte_size", default: 0, null: false
    t.index ["site_moment_id", "path"], name: "index_site_moment_files_on_site_moment_id_and_path", unique: true
    t.index ["site_moment_id"], name: "index_site_moment_files_on_site_moment_id"
  end

  create_table "site_moments", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "name", null: false
    t.string "note"
    t.integer "file_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["site_id", "created_at"], name: "index_site_moments_on_site_id_and_created_at"
    t.index ["site_id"], name: "index_site_moments_on_site_id"
  end

  create_table "site_page_views", force: :cascade do |t|
    t.bigint "site_id", null: false
    t.string "path", default: "index.html", null: false
    t.integer "status", default: 200, null: false
    t.integer "bytes_sent", default: 0, null: false
    t.boolean "is_html", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "country_code", limit: 2
    t.string "country_name"
    t.string "device_type"
    t.string "browser"
    t.string "os"
    t.index ["site_id", "country_code"], name: "index_site_page_views_on_site_id_and_country_code"
    t.index ["site_id", "created_at"], name: "index_site_page_views_on_site_id_and_created_at"
    t.index ["site_id", "device_type"], name: "index_site_page_views_on_site_id_and_device_type"
    t.index ["site_id", "is_html", "created_at"], name: "index_site_page_views_on_site_id_and_is_html_and_created_at"
    t.index ["site_id", "path"], name: "index_site_page_views_on_site_id_and_path"
    t.index ["site_id"], name: "index_site_page_views_on_site_id"
  end

  create_table "sites", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.jsonb "dashboard_widgets"
    t.boolean "gate_enabled", default: false, null: false
    t.string "seo_title"
    t.text "seo_description"
    t.string "seo_og_image"
    t.boolean "robots_index", default: true, null: false
    t.string "visitor_password"
    t.index ["account_id"], name: "index_sites_on_account_id"
    t.index ["name"], name: "index_sites_on_name", unique: true
  end

  add_foreign_key "site_dashboards", "sites"
  add_foreign_key "site_file_versions", "sites"
  add_foreign_key "site_moment_files", "site_moments"
  add_foreign_key "site_moments", "sites"
  add_foreign_key "site_page_views", "sites", name: "site_page_views_site_id_fkey"
  add_foreign_key "sites", "accounts"
end
