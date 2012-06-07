Hroot::Application.routes.draw do
  scope ENV['RAILS_RELATIVE_URL_ROOT'] || '/' do
    match 'enroll(/:code)', :controller => 'enroll', :action => 'index', :as => "enroll"
    post 'enroll_confirm(/:code)', :controller => 'enroll', :action => 'confirm', :as => 'enroll_confirm'
    post "enroll_register(/:code)", :controller => 'enroll', :action => 'register', :as => 'enroll_register'

    match 'account', :controller => 'account', :action => 'index'
    #match 'account/email', :controller => 'account', :action => 'email'
  
    match 'account/data', :controller => 'account', :action => 'data'  
  
    match 'account/alternative_email', :controller => 'account', :action => 'alternative_email'  
    match 'home/confirm_alternative_email/:confirmation_token', :controller => 'home', :action => 'confirm_alternative_email', :as => 'secondary_email_confirmation'
  
    #match 'account/password', :controller => 'account', :action => 'password'  
  
    match 'home/confirm_change_email/:confirmation_token', :controller => 'home', :action => 'confirm_change_email', :as => 'change_email_confirmation'
    match 'home/activate', :controller => 'home', :action => 'activate', :as => 'activate'
  
  
    devise_for :users, :controllers => {:registrations => "registrations"}, :path_names => { :sign_in => 'login', :sign_out => 'logout', :password => 'secret', :confirmation => 'confirmation', :sign_up => 'register' } do
      get "/login" => "devise/sessions#new"
      delete "/logout" => "devise/sessions#destroy"
      get "/logout" => "devise/sessions#destroy"
      get "/register" => "devise/registrations#new"
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
        
      resources :users do
        collection do
          post :index
        end
      end
      
      resources :locations, :except => :show
      resources :languages, :except => :show    
      resources :professions, :except => :show
      resources :studies, :except => :show
      resources :degrees, :except => :show

      match 'experiments/tag/:tag', :as => 'tagged_experiment', :controller => 'experiments', :action => 'tag'

      resources :experiments, :except => :show do
        collection do
          get :autocomplete_tags
        end
      
        member do
          get :enable
          get :disable
          get :mail
          post :mail
          get :reminders
          post :reminders
          get :invitation
          post :invitation
          post :save_mail_text
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
          end
        end
      end
    end
  

  
  
    get "home/import"
    get "home/import_test"
    get "home/index"
  
    root :to => "home#index"  
  end
end
