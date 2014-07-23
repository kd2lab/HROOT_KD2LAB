Hroot::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  
  ############# hroot configuration ########################

  # the following settings are specific to hroot, whereas general rails settings follow further down

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # generic mail for contact of your lab - used in some pages to inform users where to ask questions
  config.contact_email = 'experiments@wiso.uni-hamburg.de'

  # this email is used by the development mail interceptor (see application.rb and lib/development_mail_interceptor.rb)
  # in all other that production mode, emails will be sent to this adress instead of the real recipient
  config.interceptor_email = "mail@ingmar.net"
  # config.interceptor_subject_prefix = '[hroot]' # add a prefix to all intercepted mail subject
  
  # this email adress will be the default sender email
  config.hroot_sender_email = 'development@wiso.uni-hamburg.de'

  # log messages will be sent this email adress
  config.hroot_log_email = 'mail@ingmar.net'
  
  # set testing language to :de
  config.i18n.default_locale = :de

  # regular expression for restriction on valid email adresses - example:
  # Allow only mail adresses '...@somedomain.org'
  # see http://www.rubular.com/ for regular expressions
  config.email_restriction = {
    :regex => /.*@uni-hamburg.de$/
  }
  
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

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false
end

Rails.application.routes.default_url_options[:host] =  'test.host'
