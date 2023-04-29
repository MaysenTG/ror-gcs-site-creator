class AddSiteIdToDomains < ActiveRecord::Migration[7.0]
  def change
    add_column :domains, :site_id, :integer
  end
end
