class AddMaxSitesToAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :max_sites, :integer, default: 3
  end
end
