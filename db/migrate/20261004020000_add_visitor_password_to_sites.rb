class AddVisitorPasswordToSites < ActiveRecord::Migration[7.0]
  def up
    add_column :sites, :visitor_password, :string unless column_exists?(:sites, :visitor_password)
    remove_column :sites, :password_digest if column_exists?(:sites, :password_digest)
  end

  def down
    add_column :sites, :password_digest, :string unless column_exists?(:sites, :password_digest)
    remove_column :sites, :visitor_password if column_exists?(:sites, :visitor_password)
  end
end
