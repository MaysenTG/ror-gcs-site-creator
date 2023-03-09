class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :plan_handle, null: false
      t.string :max_sites, null: false
      t.string :max_site_size, null: false

      t.timestamps
    end
  end
end
