Hroot::Application.routes.draw do
  match 'activation/:import_token/email', :controller => 'activation', :action => 'email'
  match 'activation/:import_token/email_delivered', :controller => 'activation', :action => 'email_delivered'
  match 'activation/:import_token(/:email_token)', :controller => 'activation', :action => 'index', :as => "activation"
  
  
  match 'enroll/:code', :controller => 'enroll', :action => 'enroll_sign_in', :as => "enroll_sign_in"
  
  match 'enroll', :controller => 'enroll', :action => 'index', :as => "enroll"
  post 'enroll_confirm', :controller => 'enroll', :action => 'confirm', :as => 'enroll_confirm'
  post "enroll_register", :controller => 'enroll', :action => 'register', :as => 'enroll_register'

  match 'account', :controller => 'account', :action => 'index'
  #match 'account/email', :controller => 'account', :action => 'email'
  #match 'home/confirm_change_email/:confirmation_token', :controller => 'home', :action => 'confirm_change_email', :as => 'change_email_confirmation'
  
  match 'account/data', :controller => 'account', :action => 'data'  
  match 'account/phone', :controller => 'account', :action => 'phone'  
  match 'account/edit', :controller => 'account', :action => 'edit'  

  match 'account/alternative_email', :controller => 'account', :action => 'alternative_email'  
  match 'home/confirm_alternative_email/:confirmation_token', :controller => 'home', :action => 'confirm_alternative_email', :as => 'secondary_email_confirmation'

  match 'home/info', :controller => 'home', :action => 'info'
  match 'home/about', :controller => 'home', :action => 'about'
  match 'home/version', :controller => 'home', :action => 'version'
  match 'home/activate', :controller => 'home', :action => 'activate', :as => 'activate'
  match 'home/calendar/:key', :controller => 'home', :action => 'calendar', :as => 'public_calendar'
  
  devise_for :users, :controllers => {:registrations => "registrations"}, :path_names => { :sign_in => 'login' }, skip: :registrations 
  
  devise_scope :user do
    get "/login" => "devise/sessions#new"
    delete "/logout" => "devise/sessions#destroy"
    get "/logout" => "devise/sessions#destroy"
    
    get "/register" => "registrations#new"
    
    resource :registration,
      only: [:new, :create, :edit, :update],
      path: 'users',
      controller: 'registrations',
      as: :user_registration 
  end


  match 'admin', :controller => 'admin', :action => 'index', :as => "dashboard"
  match 'admin/index', :controller => 'admin', :action => 'index'
  match 'admin/calendar(/:year(/:month))' => 'admin#calendar', :as => :calendar, :constraints => {:year => /\d{4}/, :month => /\d{1,2}/} 
  match 'admin/templates', :controller => 'admin', :action => 'templates'

  scope '/admin' do
    match 'options', :controller => 'options', :action => 'index'
    match 'options/index', :controller => 'options', :action => 'index'
    post 'options/index'
    match 'options/emails', :controller => 'options', :action => 'emails'
    match 'options/texts', :controller => 'options', :action => 'texts'
      
      
    resources :users do
      member do
        get :login_as
        get :activate_after_import
        get :remove_from_session
      end
      collection do
        post :index
        post :create_user
        get :print
        post :send_message
      end
    end
    
    resources :locations, :except => :show
    
    match 'experiments/tag/:tag', :as => 'tagged_experiment', :controller => 'experiments', :action => 'tag'

    resources :experiments, :except => :show do
      collection do
        get :autocomplete_tags
      end
    
      member do
        get :experimenters
        post :experimenters
        get :enable
        get :disable
        get :mail
        post :mail
        get :reminders
        post :reminders
        get :invitation
        post :invitation
        get :autocomplete_tags
      end
    
      resources :sessions, :except => :show do
        collection do
          post :overlaps
        end
      
        member do
          get :reminders
          post :reminders
          get :duplicate
          get :participants
          post :participants
          get :print
        end
      end

      resources :participants do
        collection do
          get :manage
          post :manage
          post :index
          get :history
          post :send_message
        end
      end
    end
  end

  root :to => "home#index"  
end
