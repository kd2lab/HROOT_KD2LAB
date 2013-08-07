Hroot::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  config.action_mailer.default_url_options = {
    :host => 'localhost',
    :port => 3000
  }
  
  # set a site-wide path prefix here if hroot is supposed to run 
  # in a subdirectory like http://youdomain.com/subdirectory/hroot
  config.path_prefix = nil
  
  # list of supported locales
  config.locales = [:de, :en]
  config.locale_names = {:de => 'Deutsch (de)', :en => 'English (en)'}
  
  config.custom_fields = [
    { name: "somedate", title: {de: 'Ein Datum', en: 'Somedate'}, type: "date", required: true, show_in_tables: true},
    { name: "age", title: {de: 'Alter', en: 'Age'}, type: "int", required: true, show_in_tables: false},
    { name: "status", title: {de: 'Status', en: 'Status'}, type: "selection", required: true, show_in_tables: true, collection: ["A", "B", "C", "D"]},
    { name: "value", title: {de: 'Wert', en: 'Value'}, type: "int", required: false, show_in_tables: true},
    { name: "stringvalue", title: {de: 'Wert2', en: 'Value2'}, type: "string", required: true, show_in_tables: true}
  
  ]
end

Rails.application.routes.default_url_options[:host] =  'localhost:3000'

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true

ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => "587",
  :domain               => "googlemail.com",
  :user_name            => "hroottest@googlemail.com",
  :password             => "hrootamstart",
  :authentication       => "plain",
  :enable_starttls_auto => true
}
ActionMailer::Base.default :from => 'development@wiso.uni-hamburg.de'
Mail.register_interceptor(DevelopmentMailInterceptor)