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

ActiveRecord::Schema[8.0].define(version: 2025_10_02_094841) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_admin_users_on_role"
    t.index ["unlock_token"], name: "index_admin_users_on_unlock_token", unique: true
  end

  create_table "blog_categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_blog_categories_on_name", unique: true
    t.index ["slug"], name: "index_blog_categories_on_slug", unique: true
  end

  create_table "blog_comments", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.string "author_name", null: false
    t.string "author_last_name"
    t.text "body", null: false
    t.boolean "visible", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id"], name: "index_blog_comments_on_blog_id"
    t.index ["created_at"], name: "index_blog_comments_on_created_at"
    t.index ["visible"], name: "index_blog_comments_on_visible"
  end

  create_table "blog_taggings", force: :cascade do |t|
    t.bigint "blog_id", null: false
    t.bigint "blog_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id", "blog_tag_id"], name: "index_blog_taggings_on_blog_id_and_blog_tag_id", unique: true
    t.index ["blog_id"], name: "index_blog_taggings_on_blog_id"
    t.index ["blog_tag_id"], name: "index_blog_taggings_on_blog_tag_id"
  end

  create_table "blog_tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_blog_tags_on_name", unique: true
    t.index ["slug"], name: "index_blog_tags_on_slug", unique: true
  end

  create_table "blogs", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "excerpt"
    t.boolean "visible", default: false, null: false
    t.datetime "published_at"
    t.bigint "admin_user_id", null: false
    t.bigint "blog_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "author"
    t.string "seo_title"
    t.text "seo_description"
    t.index ["admin_user_id"], name: "index_blogs_on_admin_user_id"
    t.index ["blog_category_id"], name: "index_blogs_on_blog_category_id"
    t.index ["published_at"], name: "index_blogs_on_published_at"
    t.index ["slug"], name: "index_blogs_on_slug", unique: true
    t.index ["visible"], name: "index_blogs_on_visible"
  end

  create_table "enquiries", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "status", default: 0, null: false
    t.boolean "spam", default: false, null: false
    t.jsonb "form_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_enquiries_on_created_at"
    t.index ["email"], name: "index_enquiries_on_email"
    t.index ["form_data"], name: "index_enquiries_on_form_data", using: :gin
    t.index ["spam"], name: "index_enquiries_on_spam"
    t.index ["status"], name: "index_enquiries_on_status"
  end

  create_table "menu_items", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.string "label", null: false
    t.string "ancestry"
    t.integer "position"
    t.string "link_type", default: "page", null: false
    t.string "linkable_type"
    t.bigint "linkable_id"
    t.string "url"
    t.boolean "open_in_new_tab", default: false, null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "query"
    t.string "ecomm_category"
    t.string "category"
    t.index ["ancestry"], name: "index_menu_items_on_ancestry"
    t.index ["linkable_type", "linkable_id"], name: "index_menu_items_on_linkable_type_and_linkable_id"
    t.index ["menu_id", "ancestry"], name: "index_menu_items_on_menu_id_and_ancestry"
    t.index ["menu_id", "position"], name: "index_menu_items_on_menu_id_and_position"
    t.index ["menu_id"], name: "index_menu_items_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "system_menu", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_menus_on_slug", unique: true
  end

  create_table "page_pods", force: :cascade do |t|
    t.bigint "page_id", null: false
    t.bigint "pod_id", null: false
    t.string "ancestry"
    t.integer "position"
    t.jsonb "page_specific_data", default: {}, null: false
    t.boolean "visible", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "draft", default: true, null: false
    t.index "to_tsvector('simple'::regconfig, COALESCE((page_specific_data)::text, ''::text))", name: "index_page_pods_on_page_specific_data_tsv", using: :gin
    t.index ["ancestry"], name: "index_page_pods_on_ancestry"
    t.index ["page_id", "draft"], name: "index_page_pods_on_page_id_and_draft"
    t.index ["page_id", "position"], name: "index_page_pods_on_page_id_and_position"
    t.index ["page_id"], name: "index_page_pods_on_page_id"
    t.index ["page_specific_data"], name: "index_page_pods_on_page_specific_data", using: :gin
    t.index ["pod_id"], name: "index_page_pods_on_pod_id"
  end

  create_table "pages", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "meta_description"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.integer "ancestry_depth", default: 0, null: false
    t.integer "children_count", default: 0, null: false
    t.string "menu_title"
    t.boolean "show_in_menu", default: true, null: false
    t.boolean "skip_to_first_child", default: false, null: false
    t.boolean "show_in_footer", default: false, null: false
    t.string "view_template"
    t.string "redirect_path"
    t.index ["ancestry", "position"], name: "index_pages_on_ancestry_and_position"
    t.index ["ancestry"], name: "index_pages_on_ancestry"
    t.index ["ancestry_depth"], name: "index_pages_on_ancestry_depth"
    t.index ["children_count"], name: "index_pages_on_children_count"
    t.index ["show_in_footer"], name: "index_pages_on_show_in_footer"
    t.index ["show_in_menu"], name: "index_pages_on_show_in_menu"
    t.index ["slug"], name: "index_pages_on_slug", unique: true
  end

  create_table "pods", force: :cascade do |t|
    t.string "pod_type", null: false
    t.jsonb "definition", default: {}, null: false
    t.boolean "reusable", default: true, null: false
    t.integer "usage_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", default: "", null: false
    t.index "to_tsvector('simple'::regconfig, COALESCE((definition)::text, ''::text))", name: "index_pods_on_definition_tsv", using: :gin
    t.index ["definition"], name: "index_pods_on_definition", using: :gin
    t.index ["name"], name: "index_pods_on_name"
    t.index ["pod_type"], name: "index_pods_on_pod_type"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value", null: false
    t.string "data_type", default: "string"
    t.string "category"
    t.text "description"
    t.boolean "is_public", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin_only", default: false, null: false
    t.index ["admin_only"], name: "index_settings_on_admin_only"
    t.index ["category"], name: "index_settings_on_category"
    t.index ["is_public"], name: "index_settings_on_is_public"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.bigint "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blog_comments", "blogs"
  add_foreign_key "blog_taggings", "blog_tags"
  add_foreign_key "blog_taggings", "blogs"
  add_foreign_key "blogs", "admin_users"
  add_foreign_key "blogs", "blog_categories"
  add_foreign_key "menu_items", "menus"
  add_foreign_key "page_pods", "pages"
  add_foreign_key "page_pods", "pods"
end
