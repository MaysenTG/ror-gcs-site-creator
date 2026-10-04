namespace :internal do
  root to: "dashboard#show"

  resources :plans

  get "accounts/search", to: "accounts#search", as: :accounts_search
  get "accounts/new", to: "accounts#new", as: :new_account
  post "accounts/create", to: "accounts#create", as: :create_account
  get "accounts", to: "accounts#index", as: :accounts
  put "accounts/update", to: "accounts#update", as: :update_account
  delete "accounts/delete", to: "accounts#destroy", as: :delete_account
  get "accounts/:id", to: "accounts#show", as: :account

  scope "accounts/:account_id" do
    get "sites/:id", to: "sites#show", as: :account_site
    delete "sites/:id/delete_site", to: "sites#delete_site", as: :delete_account_site
    post "sites/:id/create_bucket", to: "sites#create_bucket", as: :create_account_site_bucket
  end
end
