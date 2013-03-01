TliteR3::Application.routes.draw do
  resources :password_resets

  resources :oauth_consumers do
    member do
      get :callback
      get :callback2
      match 'client/*endpoint' => 'oauth_consumers#client'
    end
  end

  resources :announcements

  resources :credentials

  #*****************************************************
  # mapping for the authentication redirections 
  get "log_in" => "sessions#new", :as => "log_in"
  get "log_out" => "sessions#destroy", :as => "log_out" 
  get "sign_up" => "users#new", :as => "sign_up" 
  
  resources :users  
  resources :sessions 
  #*****************************************************

  resources :runs
  #*****************************************************
  # mapping for refreshing runs list
  get 'runs_refresh_list'  => 'runs#refresh_list'
  # mapping for refreshing results if run has not finished
  match 'runs/refresh/:id'  => 'runs#refresh'
  match 'runs/interaction/:id/:interactionid' => 'runs#interaction'
  #*****************************************************


  put '/workflows/:id/make_private' => 'workflows#make_private', :as => 'make_private'

  resources :workflows do
    member do
      put "make_public"
      put "make_private"
    end
  end

  #*****************************************************
  # mapping for the redirection when checking results
  match 'runs/', :controller => 'runs', :action => 'update_all'
  #*****************************************************
  #*****************************************************
  # mapping for the redirection when creating a new run
  match 'workflows/:id/newrun/', :controller => 'runs', :action => 'new_run'
  #*****************************************************
  


  #*****************************************************
  # mapping for the redirection when downloading a result
  match 'results/:id/download/', :controller => 'result', :action => 'download'
  #*****************************************************

  get '/no_configuration' => "static#no_configuration" , :as => 'no_configuration'


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
