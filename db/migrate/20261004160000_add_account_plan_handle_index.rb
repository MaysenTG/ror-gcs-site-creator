class AddAccountPlanHandleIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :accounts, :plan_handle, if_not_exists: true
  end
end
