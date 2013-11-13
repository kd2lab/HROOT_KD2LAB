require 'development_mail_interceptor'

# register a mail intercepter, which prevents sending out live email in environments other that production
# configure in development.rb
# see also lib/development_mail_intercepter.rb
ActionMailer::Base.register_interceptor(DevelopmentMailInterceptor)

