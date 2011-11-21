Hroot::Application.routes.draw do
  
  match 'enroll(/:code)', :controller => 'enroll', :action => 'index', :as => "enroll"
  get "enroll/save"

  match '/calendar(/:year(/:month))' => 'calendar#index', :as => :calendar, :constraints => {:year => /\d{4}/, :month => /\d{1,2}/}

  devise_for :users, :controllers => {:registrations => "registrations"}, :path_names => { :sign_in => 'login', :sign_out => 'logout', :password => 'secret', :confirmation => 'confirmation', :sign_up => 'register' } do
    get "/login" => "devise/sessions#new"
    delete "/logout" => "devise/sessions#destroy"
    get "/logout" => "devise/sessions#destroy"
    get "/register" => "devise/registrations#new"
  end
  
  
  match 'admin', :controller => 'admin', :action => 'index'
  match 'admin/index', :controller => 'admin', :action => 'index'
  
  scope '/admin' do
    match 'options', :controller => 'options', :action => 'index'
    match 'options/index', :controller => 'options', :action => 'index'
    post 'options/index'
    
    match 'options/emails', :controller => 'options', :action => 'emails'
      
      
        
    resources :users do
      collection do
        post :filter
      end
    end
      
    resources :locations, :except => :show

    resources :experiments do
      member do
        get :invitation
        post :invitation
      end
      
      resources :sessions do
        member do
          post :duplicate
        end
      end

      resources :participants do
        collection do
          get :manage
          post :manage
          post :index
        end
      end
    end
  end
  

  match 'account', :controller => 'account', :action => 'index'
  match 'account/:action', :controller => 'account'
    
  
  get "home/import"
  get "home/import_test"
  
  get "home/index"
  match "home/calendar/:id", :controller => 'home', :action => 'calendar', :as => 'calendar'
  
  root :to => "home#index"
  
  #map.resource :account, :controller => "users"
  #map.resources :password_resets
  #map.resources :users
  #map.resource :user_session
  #map.root :controller => "user_sessions", :action => "new"
  
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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
