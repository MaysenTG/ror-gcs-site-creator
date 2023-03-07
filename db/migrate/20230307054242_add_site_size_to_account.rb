class AddSiteSizeToAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :max_site_size, :integer, default: 1
  end
end
