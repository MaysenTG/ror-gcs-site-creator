class CreateSitePageViews < ActiveRecord::Migration[7.0]
  def change
    create_table :site_page_views do |t|
      t.references :site, null: false, foreign_key: true
      t.string :path, null: false, default: "index.html"
      t.integer :status, null: false, default: 200
      t.integer :bytes_sent, null: false, default: 0
      t.boolean :is_html, null: false, default: false
      t.datetime :created_at, null: false
    end

    add_index :site_page_views, [:site_id, :created_at]
    add_index :site_page_views, [:site_id, :is_html, :created_at]
    add_index :site_page_views, [:site_id, :path]
  end
end
