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
  # config.serve_static_assets = true
  # config.assets.debug = true
  
  
  # Enable serving of images, stylesheets, and javascripts from an asset server
  #config.action_controller.asset_host = "https://www.wiso.uni-hamburg.de"

  # Disable delivery errors, bad email addresses will be ignored
  #config.action_mailer.delivery_method = :sendmail
  #config.action_mailer.perform_deliveries = true
  
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  #config.action_mailer.smtp_settings = {
  #  :address              => "localhost",
  #  :port                 => "25"
  #}
  config.action_mailer.raise_delivery_errors = true
 

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  config.action_mailer.default_url_options = {
    :protocol => 'https',
    :host => 'www.wiso.uni-hamburg.de/hroot'
  }
  
  # list of supported locales
  config.locales = [:de, :en]
  config.locale_names = {:de => 'Deutsch (de)', :en => 'English (en)'}

  config.contact_email = 'experiments@wiso.uni-hamburg.de'

  
  #config.assets.prefix = "assettest"
  config.path_prefix = nil
  
  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "mail@ingmar.net"
  
  # this email adress will be the default sender email
  config.hroot_sender_email = 'development@wiso.uni-hamburg.de'

  # log messages will be sent this email adress
  config.hroot_log_email = 'mail@ingmar.net'
  
  # configure uploads directory
  config.upload_dir = Rails.root.join('uploads')
  
  config.user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :begin_of_studies, :created_at, :noshow_count, :participations_count]
  config.add_user_table_columns = [:fullname, :role, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
  config.participants_table_columns = [:fullname, :role, :email, :course_of_studies, :noshow_count, :participations_count, :session]
  config.session_participants_table_columns = [:counter, :fullname, :email, :course_of_studies, :gender, :noshow_count, :participations_count]
  
end

ActionMailer::Base.default :from => 'experiments@wiso.uni-hamburg.de'

Rails.application.routes.default_url_options[:host] =  'hroot.ingmar.net'
Rails.application.routes.default_url_options[:protocol] =  'https'
Mail.register_interceptor(DevelopmentMailInterceptor)

Hroot::Application.config.middleware.use ExceptionNotification::Rack,
  :email => {
    :email_prefix => "[hroot qa] ",
    :sender_address => %{"mail@ingmar.net"},
    :exception_recipients => %w{mail@ingmar.net}
  }

