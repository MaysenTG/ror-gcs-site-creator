Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  # Fly.io / load-balancer health check
  get "/up", to: ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }

  # Published site URLs:
  #   Path style (always works):     http://localhost:3000/s/my-site/
  #   Local subdomain:               http://my-site.localhost:3000/
  #   Production subdomain:          https://my-site.maysengreenwood.com/
  get "/s/:site_name", to: "published_sites#show", as: :published_site
  get "/s/:site_name/*path", to: "published_sites#show", format: false
  post "/s/:site_name/gate", to: "published_sites#unlock", as: :published_site_gate

  site_host_domains = %w[localhost lvh.me maysengreenwood.com]
  reserved_subdomains = %w[www app admin api cdn mail ftp]
  constraints(->(req) {
    subdomain = req.subdomains.first.to_s
    req.subdomains.present? &&
      site_host_domains.include?(req.domain.to_s) &&
      reserved_subdomains.exclude?(subdomain)
  }) do
    get "/", to: "published_sites#show_via_subdomain"
    post "/gate", to: "published_sites#unlock"
    get "/*path", to: "published_sites#show_via_subdomain", format: false
  end
  
  get 'accounts/get_plans'
  post 'checkout/create_checkout_session'
  get 'checkout/success'
  get 'checkout/cancel'
  post 'checkout/handle_checkout_session_complete'
  
  devise_for :accounts, controllers: { registrations: 'registrations' }
  
  namespace :admin do
    get '/test_path/show' => 'sites#test_show'
    get 'sites/new' => 'sites#new'
    get 'sites' => 'sites#index'
    get 'sites/all' => 'sites#all_sites'
    get 'dashboards' => 'dashboard_hub#index', as: :dashboard_hub
    get 'sites/:site_name/dashboard' => 'sites#dashboard'
    get 'sites/:site_name' => 'sites#show'
    post 'sites/validate_site_name' => 'sites#validate_site_name'
    post 'sites/create_new_site' => 'sites#create'
    post 'sites/:site_name/clone' => 'sites#clone', as: :clone_site
    patch 'sites/:site_name/settings' => 'sites#update_settings', as: :site_settings
    delete 'sites/delete' => 'sites#delete'
    
    get 'sites/:site_name/files/editor' => 'files#show'
    post 'sites/:site_name/files/update' => 'files#update'
    post 'sites/:site_name/files/new' => 'files#create'
    post 'sites/:site_name/files/upload' => 'files#upload'
    delete '/sites/:site_name/delete' => 'files#delete'
    delete '/sites/:site_name/files/delete' => 'files#delete'
    patch 'sites/:site_name/files/rename' => 'files#rename'
    get 'sites/:site_name/files/versions' => 'files#versions', as: :file_versions
    post 'sites/:site_name/files/versions/restore' => 'files#restore_version', as: :restore_file_version
    
    post 'sites/:site_name/folders/new' => 'files#create_folder'
    
    scope 'sites/:site_name' do
      resources :domains
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
      get 'ship_check' => 'site_tools#ship_check', as: :ship_check
      post 'theme_remix' => 'site_tools#apply_theme', as: :theme_remix
      post 'palette_remix' => 'site_tools#apply_palette', as: :palette_remix
      post 'analytics/query' => 'analytics#query', as: :analytics_query
      get 'analytics/catalog' => 'analytics#catalog', as: :analytics_catalog
      get 'analytics/paths' => 'analytics#paths', as: :analytics_paths
      post 'analytics/events' => 'analytics#events', as: :analytics_events
    end
    
    get '/proxy/site/lookup' => 'sites#get_custom_domain'
    
  end
  
  namespace :internal do
    resources :plans
    get 'accounts/search'
    get 'accounts/new'
    post 'accounts/create'
    get 'accounts' => 'accounts#index'
    put 'accounts/update'
    delete 'accounts/delete' => 'accounts#destroy'
    get 'accounts/:id' => 'accounts#show'
    scope 'accounts/:account_id' do
      get 'sites/:id' => 'sites#show', as: 'account_site'
      delete 'sites/:id/delete_site' => 'sites#delete_site'
      post 'sites/:id/create_bucket' => 'sites#create_bucket'
    end
  end
  
  get 'home/pricing', to: 'home#pricing'
  get 'pricing', to: 'home#pricing'
  root 'home#show'
  
  # namespace :api do
  #   namespace :v1 do
  #     get 'posts/index'
  #     post 'posts/create'
  #     delete 'posts/:id', to: 'posts#destroy'
  #     post 'emails/bulk/send' => 'emails#send_bulk'
      
  #     post 'sites/create' 
  #     get 'sites/all' => 'sites#all'
  #     get 'sites/:site_name' => 'sites#show'
  #     get 'sites/check_name/:site_name' => 'sites#check_name'
  #     delete 'sites/:site_id' => 'sites#delete'
      
  #     post 'files/create' => 'files#create'
  #     post 'files/folder/create' => 'files#create_folder'
  #     delete 'sites/:site_name/files/delete' => 'files#delete'
  #     get 'sites/:site_name/files/show' => 'files#show'
  #     put 'sites/:site_name/files/edit' => 'files#edit'
  #     post 'sites/files/rename' => 'files#rename'
  #     post 'sites/files/new/upload' => 'files#upload'
  #   end
  # end
end
