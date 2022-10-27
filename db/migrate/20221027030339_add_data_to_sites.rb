class AddDataToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :sites, :name, :string, null: false, :unique => true
  end
end
