Rails.application.routes.draw do
  devise_for :accounts
  #get 'emails'
  #get 'emails/new'
  resources :emails
  resources :posts
  resources :sites
  
  get 'sites/:site_id/files/:file' => 'sites#show_file'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "posts#index"
  
  namespace :api do
    namespace :v1 do
      get 'posts/index'
      post 'posts/create'
      delete 'posts/:id', to: 'posts#destroy'
      post 'emails/bulk/send' => 'emails#send_bulk'
      
      post 'sites/create' 
      get 'sites/all' => 'sites#all'
      get 'sites/:site_id' => 'sites#show'
      post 'files/create' => 'sites#create_file'
      
      get 'sites/:site_id/files/:file_name' => 'sites#edit_file'
      put 'sites/:site_id/files/:file_name' => 'sites#update_file'
      delete 'sites/:site_id/files/:file_name' => 'sites#delete_file'
      delete 'sites/:site_id' => 'sites#delete_site'
    end
  end
end
