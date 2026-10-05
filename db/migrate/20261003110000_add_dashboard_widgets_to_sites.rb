class AddDashboardWidgetsToSites < ActiveRecord::Migration[7.0]
  def change
    add_column :sites, :dashboard_widgets, :json
  end
end
