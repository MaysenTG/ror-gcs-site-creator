class CreateSiteFiles < ActiveRecord::Migration[8.1]
  def change
    create_table :site_files do |t|
      t.references :site, null: false, foreign_key: true
      t.string :path, null: false
      t.string :kind, null: false, default: "file"
      t.bigint :byte_size, null: false, default: 0
      t.string :content_type
      t.datetime :remote_updated_at

      t.timestamps
    end

    add_index :site_files, %i[site_id path], unique: true
    add_index :site_files, %i[site_id kind]
  end
end
