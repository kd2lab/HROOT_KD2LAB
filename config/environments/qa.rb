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

  # See everything in the log (default is :info)
  config.log_level = :info

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  # config.serve_static_assets = true
  # config.assets.debug = true
  
  # enable or disable actual delivery
  config.action_mailer.perform_deliveries = true
  
  #send method
  config.action_mailer.delivery_method = :sendmail
  
   #configure action mailer - example: use local sendmail
  config.action_mailer.smtp_settings = {
    :address              => "localhost",
    :port                 => "25"
  }
  
  config.action_mailer.raise_delivery_errors = true
 
  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  config.action_mailer.default_url_options = {
    :protocol => 'http',
    :host => 'hroot.ingmar.net'
  }
  
  # are users allowed to always edit their optional data?
  config.users_can_edit_optional_data = false

  config.contact_email = 'experiments@wiso.uni-hamburg.de'
  
  config.recipient_of_audit_reports = "someemail@somedomain.de"
  
  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "hroottest@googlemail.com"
  
  # this email adress will be the default sender email
  config.hroot_sender_email = 'hroottest@googlemail.com'

  # log messages will be sent this email adress
  config.hroot_log_email = 'mail@ingmar.net'
  
  # configure uploads directory
  config.upload_dir = Rails.root.join('uploads')

  #config.assets.prefix = "assettest"
  config.path_prefix = nil  
end

Hroot::Application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    :email_prefix => "[hroot qa] ",
    :sender_address => %{"mail@ingmar.net"},
    :exception_recipients => %w{mail@ingmar.net}
  }

