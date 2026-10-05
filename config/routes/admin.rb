namespace :admin do
  get "/test_path/show" => "sites#test_show"
  get "sites/new" => "sites#new"
  get "sites" => "sites#index"
  get "sites/all" => "sites#all_sites"
  get "dashboards" => "dashboard_hub#index", as: :dashboard_hub
  get "sites/:site_name/dashboard" => "sites#dashboard"
  get "sites/:site_name" => "sites#show"
  post "sites/validate_site_name" => "sites#validate_site_name"
  post "sites/create_new_site" => "sites#create"
  post "sites/:site_name/clone" => "sites#clone", as: :clone_site
  patch "sites/:site_name/settings" => "sites#update_settings", as: :site_settings
  delete "sites/delete" => "sites#delete"

  get "sites/:site_name/files/editor" => "files#show"
  post "sites/:site_name/files/update" => "files#update"
  post "sites/:site_name/files/new" => "files#create"
  post "sites/:site_name/files/upload" => "files#upload"
  delete "/sites/:site_name/delete" => "files#delete"
  delete "/sites/:site_name/files/delete" => "files#delete"
  patch "sites/:site_name/files/rename" => "files#rename"
  get "sites/:site_name/files/versions" => "files#versions", as: :file_versions
  post "sites/:site_name/files/versions/restore" => "files#restore_version", as: :restore_file_version

  post "sites/:site_name/folders/new" => "files#create_folder"

  scope "sites/:site_name" do
    resources :domains do
      member do
        get :dns_check
      end
    end
    resources :dashboards, only: %i[index show create update destroy] do
      member do
        patch :layout
      end
    end
    resources :moments, only: %i[index show create] do
      member do
        post :restore
      end
    end
    get "ship_check" => "site_tools#ship_check", as: :ship_check
    post "theme_remix" => "site_tools#apply_theme", as: :theme_remix
    post "palette_remix" => "site_tools#apply_palette", as: :palette_remix
    post "analytics/query" => "analytics#query", as: :analytics_query
    get "analytics/catalog" => "analytics#catalog", as: :analytics_catalog
    get "analytics/paths" => "analytics#paths", as: :analytics_paths
    post "analytics/events" => "analytics#events", as: :analytics_events
  end

  get "/proxy/site/lookup" => "sites#get_custom_domain"
end
