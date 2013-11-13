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
  
  # only allow certain email adresses on signup
  config.email_restriction = {
    :regex => /(.*@uni-hamburg.de$)|(.*@student.uni-hamburg.de$)|(.*@ingmar.net$)/
  }
  
  # columns in user table
  config.user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :begin_of_studies, :created_at, :noshow_count, :participations_count]
  config.add_user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
  config.participants_table_columns = [:fullname, :role, :email, :course_of_studies, :noshow_count, :participations_count, :session]
  config.session_participants_table_columns = [:counter, :fullname, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
  
  #configure action mailer - example: use gmail as mail service
  config.action_mailer.smtp_settings = {
    :address              => "smtp.gmail.com",
    :port                 => "587",
    :domain               => "googlemail.com",
    :user_name            => "hroottest@googlemail.com",
    :password             => "hrootamstart",
    :authentication       => "plain",
    :enable_starttls_auto => true
  }
  
  config.action_mailer.delivery_method = :smtp
  
  # enable or disable actual delivery
  config.action_mailer.perform_deliveries = true

  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "mail@ingmar.net"
  
  # this email adress will be the default sender email
  config.hroot_sender_email = 'development@wiso.uni-hamburg.de'

  # log messages will be sent this email adress
  config.hroot_log_email = 'mail@ingmar.net'
  
  # configure uploads directory
  config.upload_dir = Rails.root.join('uploads')
  
end

#Rails.application.routes.default_url_options[:host] =  'localhost:3000'

#ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.perform_deliveries = true

#ActionMailer::Base.smtp_settings = {
#  :address              => "smtp.gmail.com",
#  :port                 => "587",
#  :domain               => "googlemail.com",
#  :user_name            => "hroottest@googlemail.com",
#  :password             => "hrootamstart",
#  :authentication       => "plain",
#  :enable_starttls_auto => true
#}
#ActionMailer::Base.default :from => Rails.configuration.hroot_sender_email
