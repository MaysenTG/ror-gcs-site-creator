Rails.application.routes.draw do
  get 'accounts/get_plans'
  post 'checkout/create_checkout_session'
  get 'checkout/success'
  get 'checkout/cancel'
  post 'checkout/handle_checkout_session_complete'

  
  
  # Working on this
  #get 'pricing' => 'home#pricing'
  
  devise_for :accounts, controllers: { registrations: 'registrations' }
  
  namespace :admin do
    get '/test_path/show' => 'sites#test_show'
    #resources :sites
    get 'sites/new' => 'sites#new'
    get 'sites' => 'sites#index'
    get 'sites/all' => 'sites#all_sites'
    get 'sites/:site_name' => 'sites#show'
    post 'sites/validate_site_name' => 'sites#validate_site_name'
    post 'sites/create_new_site' => 'sites#create'
    delete 'sites/delete' => 'sites#delete'
    
    #get 'sites/:site_name/files/edit' => 'files#show'
    get 'sites/:site_name/files/editor' => 'files#show'
    post 'sites/:site_name/files/update' => 'files#update'
    post 'sites/:site_name/files/new' => 'files#create'
    post 'sites/:site_name/files/upload' => 'files#upload'
    delete '/sites/:site_name/delete' => 'files#delete'
    delete '/sites/:site_name/files/delete' => 'files#delete'
    patch 'sites/:site_name/files/rename' => 'files#rename'
    
    post 'sites/:site_name/folders/new' => 'files#create_folder'
    # resources :sites do 
    #   resources :files
    # end
    #get 'sites/:site_id/files/:file_name' => 'sites#show_file'
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
  
  root 'home#show'
  
  namespace :api do
    namespace :v1 do
      get 'posts/index'
      post 'posts/create'
      delete 'posts/:id', to: 'posts#destroy'
      post 'emails/bulk/send' => 'emails#send_bulk'
      
      post 'sites/create' 
      get 'sites/all' => 'sites#all'
      get 'sites/:site_name' => 'sites#show'
      get 'sites/check_name/:site_name' => 'sites#check_name'
      delete 'sites/:site_id' => 'sites#delete'
      
      post 'files/create' => 'files#create'
      post 'files/folder/create' => 'files#create_folder'
      delete 'sites/:site_name/files/delete' => 'files#delete'
      get 'sites/:site_name/files/show' => 'files#show'
      put 'sites/:site_name/files/edit' => 'files#edit'
      post 'sites/files/rename' => 'files#rename'
      post 'sites/files/new/upload' => 'files#upload'
    end
  end
end
