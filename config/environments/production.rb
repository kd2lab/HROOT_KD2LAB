Hroot::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  config.log_level = :info

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  #config.serve_static_assets = false

  # Enable serving of images, stylesheets, and javascripts from an asset server
  #config.action_controller.asset_host = "https://www.wiso.uni-hamburg.de"

  # set a site-wide path prefix here if hroot is supposed to run 
  # in a subdirectory like http://youdomain.com/subdirectory/hroot
  config.path_prefix = nil

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

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.smtp_settings = {
    :address              => "localhost",
    :port                 => "25"
  }
 
  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
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
