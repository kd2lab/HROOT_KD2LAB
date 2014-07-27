Hroot::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  
  ############# hroot configuration ########################

  # the following settings are specific to hroot, whereas general rails settings follow further down

  # enable or disable actual delivery - set this to true to enable email sending
  config.action_mailer.perform_deliveries = true
  
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

  #config.action_mailer.delivery_method = :sendmail
  #config.action_mailer.perform_deliveries = true
  #config.action_mailer.smtp_settings = {
  #  :address              => "localhost",
  #  :port                 => "25"
  #}

  # generic mail for contact of your lab - used in some pages to inform users where to ask questions
  config.contact_email = '<Your contact email>'

  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "<Your email>"
  # config.interceptor_subject_prefix = '[hroot]' # add a prefix to all intercepted mail subject
  
  # this email adress will be the default sender email
  config.hroot_sender_email = '<Some email which acts as default sender address>'

  # log messages will be sent this email adress
  config.hroot_log_email = '<your email adress>'
  

  # regular expression for restriction on valid email adresses - example:
  # Allow only mail adresses '...@somedomain.org'
  # see http://www.rubular.com/ for regular expressions
  #config.email_restriction = {
  #  :regex => /.*@somedomain.org$/
  #}
  
  # are users allowed to always edit their optional data?
  config.users_can_edit_optional_data = false
  
  
  # configure uploads directory - you can put your own path here
  config.upload_dir = Rails.root.join('uploads')

  # set a site-wide path prefix here if hroot is supposed to run 
  # in a subdirectory like http://youdomain.com/subdirectory/hroot
  # config.path_prefix = '/root'
  config.path_prefix = ''

  # catch all exceptions with exception notifier
  config.catch_exceptions = false

  # asset serving in debug mode
  config.assets.debug = true


  ##################### General Rails configuration #####################

  # You can probably leave most of the values here untouched

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # See everything in the log (default is :info)
  config.log_level = :info

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
end

# Rails.application.routes.default_url_options[:host] =  'www.yoursite.com/hroot'
# Rails.application.routes.default_url_options[:protocol] =  'https'

# enable exception mailing
#Hroot::Application.config.middleware.use ExceptionNotification::Rack,
#  :email => {
#    :email_prefix => "[<your email prefix>] ",
#    :sender_address => %{"<some@email.adress>"},
#    :exception_recipients => %w{<some@email.adress>}
#  }
