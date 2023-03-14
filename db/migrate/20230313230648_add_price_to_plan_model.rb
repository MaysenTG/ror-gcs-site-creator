class AddPriceToPlanModel < ActiveRecord::Migration[7.0]
  def change
    add_column :plans, :price, :integer, precision: 8, scale: 2
  end
end
