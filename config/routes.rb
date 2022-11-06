Rails.application.routes.draw do
  get 'file/create'
  get 'file/edit'
  get 'file/show'
  get 'file/rename'
  get 'file/set_main'
  get 'file/set_404'
  devise_for :accounts
  
  
  get '/test_response', to: 'home#test_response'
  #get 'emails'
  #get 'emails/new'
  resources :emails
  resources :posts
  
  namespace :admin do
    resources :sites
    get 'sites/:site_id/files/:file_name' => 'sites#show_file'
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
