class CreateSiteFileVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :site_file_versions do |t|
      t.references :site, null: false, foreign_key: true
      t.string :path, null: false
      t.text :content, null: false
      t.integer :byte_size, null: false, default: 0
      t.datetime :created_at, null: false
    end

    add_index :site_file_versions, %i[site_id path created_at], name: "index_site_file_versions_on_site_path_created"
    add_index :site_file_versions, :created_at
  end
end
