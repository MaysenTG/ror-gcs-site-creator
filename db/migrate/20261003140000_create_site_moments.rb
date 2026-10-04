class CreateSiteMoments < ActiveRecord::Migration[7.0]
  def change
    create_table :site_moments do |t|
      t.references :site, null: false, foreign_key: true
      t.string :name, null: false
      t.string :note
      t.integer :file_count, null: false, default: 0
      t.datetime :created_at, null: false
    end

    create_table :site_moment_files do |t|
      t.references :site_moment, null: false, foreign_key: true
      t.string :path, null: false
      t.text :content, null: false
      t.integer :byte_size, null: false, default: 0
    end

    add_index :site_moments, %i[site_id created_at]
    add_index :site_moment_files, %i[site_moment_id path], unique: true
  end
end
