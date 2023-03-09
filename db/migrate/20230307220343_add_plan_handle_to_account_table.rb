class AddPlanHandleToAccountTable < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :plan_handle, :string, default: "free"
  end
end
