require File.expand_path('../boot', __FILE__)

require 'rails/all'

require "./lib/custom_field_classes.rb"
require "./lib/search_classes.rb"

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Hroot
  class Application < Rails::Application
    ############# hroot specific configuration #########################

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake time:zones:all" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'
    config.active_record.default_timezone = :local
    
    # list of supported locales
    config.locales = [:en, :de]
    config.locale_names = {:en => 'English (en)', :de => 'Deutsch (de)'}
    config.i18n.enforce_available_locales = true
    config.i18n.default_locale = :en
    

    # columns in user table
    config.user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :begin_of_studies, :created_at, :noshow_count, :participations_count]
    config.user_table_print_columns = [:counter, :fullname, :role, :email, :course_of_studies, :gender, :begin_of_studies, :created_at, :noshow_count, :participations_count]
    config.user_table_csv_columns = [:id, :lastname, :firstname, :email, :secondary_email, :gender, :birthday, :matrikel, :phone, :country_name,  :role,  :language, :begin_of_studies, :course_of_studies,  :degree, :created_at, :noshow_count, :participations_count, :deleted, :comment]
    config.session_participants_table_print_columns = [:counter, :fullname, :phone, :gender, :noshow, :showup, :participated, :seat_nr, :payment]
    config.session_participants_table_csv_columns = [:id, :lastname, :firstname, :noshow, :showup, :participated, :seat_nr, :payment, :session, :email, :secondary_email, :gender, :birthday, :matrikel, :phone, :country_name,  :role,  :language, :begin_of_studies, :course_of_studies,  :degree, :created_at, :noshow_count, :participations_count, :deleted, :comment]
  
    config.participants_table_print_columns = [:counter, :fullname, :showup, :participated, :noshow, :seat_nr, :payment, :session, :role, :email, :course_of_studies, :gender, :noshow_count, :participations_count, :deleted]
    config.participants_table_csv_columns = [:id, :lastname, :firstname, :showup, :participated, :noshow, :seat_nr, :payment, :session, :email, :secondary_email, :gender, :birthday, :matrikel, :phone, :country_name,  :role,  :language, :begin_of_studies, :course_of_studies,  :degree, :created_at, :noshow_count, :participations_count, :deleted, :comment]
  
    config.add_user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
    config.participants_table_columns = [:fullname, :role, :email, :course_of_studies, :noshow_count, :participations_count, :session]
    config.session_participants_table_columns = [:counter, :fullname, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
  


    ############# general rails configuration - leave unchanged unless you know what you're doing ########


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # enforce valid locale
    config.i18n.enforce_available_locales = true    
    
    # all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w(jquery chosen.jquery.min)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]
    
    # add view routes for registration controller override
    config.paths["app/views"] << "app/views/devise"
    config.assets.enabled = true
    
    # Catch 404s
    config.after_initialize do |app|
      app.routes.append{match '*path', :to => 'application#render_404'}
    end  
  end
end

