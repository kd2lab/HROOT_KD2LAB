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
  
  # set a site-wide path prefix here if hroot is supposed to run 
  # in a subdirectory like http://youdomain.com/subdirectory/hroot
  config.path_prefix = nil
  
  config.assets.debug = true
  
  # Mail configuration

  # enable or disable actual delivery - set this to false to enable email sending
  config.action_mailer.perform_deliveries = false

  
  # ---------- email config example 1: send emails via gmail -----------------------

  # send method
  # config.action_mailer.delivery_method = :smtp
  
  #configure action mailer - example: use gmail as mail service
  #config.action_mailer.smtp_settings = {
  #  :address              => "smtp.gmail.com",
  #  :port                 => "587",
  #  :domain               => "googlemail.com",
  #  :user_name            => "<your_gmail_account>@googlemail.com",
  #  :password             => "<your_password>",
  #  :authentication       => "plain",
  #  :enable_starttls_auto => true
  #}

  # ---------- email config example 2: send emails via local sendmail -----------------------

  #config.action_mailer.delivery_method = :smtp
  #config.action_mailer.perform_deliveries = true
  #config.action_mailer.smtp_settings = {
  #  :address              => "localhost",
  #  :port                 => "25"
  #}


  # urls in emails - add your site url here - you can delete port if your webserver runs on port 80
  config.action_mailer.default_url_options = {
    :protocol => "http",
    :host => 'localhost',
    :port => 3000
  }

  # regular expression for restriction on valid email adresses - example:
  # Allow only mail adresses '...@somedomain.org'
  # see http://www.rubular.com/ for regular expressions
  #config.email_restriction = {
  #  :regex => /.*@somedomain.org$/
  #}
  
  # are users allowed to always edit their optional data?
  config.users_can_edit_optional_data = false
  
  # generic mail for contact of your lab - used in some pages to inform users where to ask questions
  config.contact_email = '<Your contact email>'

  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "<Your email>"
  
  # this email adress will be the default sender email
  config.hroot_sender_email = '<Some email which acts as default sender adress>'

  # log messages will be sent this email adress
  config.hroot_log_email = '<your email adress>'
  
  # configure uploads directory - you can put your own path here
  config.upload_dir = Rails.root.join('uploads')

  # catch all exceptions with exception notifier
  config.catch_exceptions = true
end

# enable exception mailing
#Hroot::Application.config.middleware.use ExceptionNotification::Rack,
#  :email => {
#    :email_prefix => "[<your email prefix>] ",
#    :sender_address => %{"<some@email.adress>"},
#    :exception_recipients => %w{<some@email.adress>}
#  }
