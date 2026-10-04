class AddDeviceAndCountryToSitePageViews < ActiveRecord::Migration[7.0]
  def change
    add_column :site_page_views, :country_code, :string, limit: 2
    add_column :site_page_views, :country_name, :string
    add_column :site_page_views, :device_type, :string
    add_column :site_page_views, :browser, :string
    add_column :site_page_views, :os, :string

    add_index :site_page_views, [:site_id, :country_code]
    add_index :site_page_views, [:site_id, :device_type]
  end
end
