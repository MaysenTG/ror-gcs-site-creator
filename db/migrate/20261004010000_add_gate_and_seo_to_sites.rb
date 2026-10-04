class AddGateAndSeoToSites < ActiveRecord::Migration[7.0]
  def change
    change_table :sites, bulk: true do |t|
      t.boolean :gate_enabled, null: false, default: false
      t.string :seo_title
      t.text :seo_description
      t.string :seo_og_image
      t.boolean :robots_index, null: false, default: true
    end
  end
end
