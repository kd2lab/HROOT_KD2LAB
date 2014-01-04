Hroot::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.action_mailer.default_url_options = {
    :host => 'localhost',
    :port => 3000
  }

  config.contact_email = 'experiments@wiso.uni-hamburg.de'

 
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  
  # list of supported locales
  config.locales = [:de, :en]
  config.locale_names = {:de => 'Deutsch (de)', :en => 'English (en)'}
  
  #config.email_regexp = /(.*@uni-hamburg.de$)|(.*@student.uni-hamburg.de$)|(.*@ingmar.net$)/
  
  config.email_restriction = {
    :regex => /.*@uni-hamburg.de$/
  }
  
  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "mail@ingmar.net"
  
  # this email adress will be the default sender email
  config.hroot_sender_email = 'development@wiso.uni-hamburg.de'

  # log messages will be sent this email adress
  config.hroot_log_email = 'mail@ingmar.net'
  
  # configure uploads directory
  config.upload_dir = Rails.root.join('uploads')
  
  # columns in user table
  config.user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :begin_of_studies, :created_at, :noshow_count, :participations_count]
  config.add_user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
  config.participants_table_columns = [:fullname, :role, :email, :course_of_studies, :noshow_count, :participations_count, :session]
  
  config.recipient_of_audit_reports = "someemail@somedomain.co.uk"
  
  
end

Rails.application.routes.default_url_options[:host] =  'test.host'
