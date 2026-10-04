class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :sites, :name, unique: true unless index_exists?(:sites, :name)
    add_index :domains, :domain, unique: true unless index_exists?(:domains, :domain)
    add_index :domains, :site_id unless index_exists?(:domains, :site_id)
    add_index :plans, :plan_handle, unique: true unless index_exists?(:plans, :plan_handle)
  end
end
