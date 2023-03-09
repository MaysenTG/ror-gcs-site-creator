Rails.application.routes.draw do
  get 'files/create'
  get 'files/edit'
  get 'files/show'
  get 'files/delete'
  get 'files/rename'
  get 'sites/index'
  get 'sites/show'
  get 'sites/new'
  get 'sites/delete'
  get 'sites/create'
  get 'file/create'
  get 'file/edit'
  get 'file/show'
  get 'file/rename'
  get 'file/set_main'
  get 'file/set_404'
  #devise_for :accounts
  devise_for :accounts, controllers: { registrations: 'registrations' }
  
  
  get '/test_response', to: 'home#test_response'
  #get 'emails'
  #get 'emails/new'
  resources :emails
  resources :posts
  
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
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
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
