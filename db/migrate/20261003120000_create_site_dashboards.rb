class CreateSiteDashboards < ActiveRecord::Migration[7.0]
  def up
    create_table :site_dashboards do |t|
      t.references :site, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :is_default, null: false, default: false
      t.jsonb :global_filters, null: false, default: {}
      t.jsonb :layout, null: false, default: []
      t.timestamps
    end

    add_index :site_dashboards, [:site_id, :slug], unique: true
    add_index :site_dashboards, [:site_id, :is_default]

    say_with_time "seed Overview dashboards" do
      Site.find_each do |site|
        next if site.site_dashboards.exists?

        SiteDashboard.create_overview_for!(site)
      end
    end
  end

  def down
    drop_table :site_dashboards
  end
end
