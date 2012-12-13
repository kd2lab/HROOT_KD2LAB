if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'http://rubygems.org'

gem 'rails', '3.2.9'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2'

# Use unicorn as the web server
gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'
gem 'capistrano-ext'
# gem 'rvm-capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
gem 'debugger'
gem 'haml'
gem 'ledermann-rails-settings', :require => 'rails-settings'
gem 'sequel'
gem 'jquery-rails', '>= 1.0.12'
gem 'will_paginate'
gem 'devise'
gem 'simple_form'
gem 'event-calendar', :require => 'event_calendar'
gem 'exception_notification'
gem 'icalendar'
gem 'coffee-script'
gem 'cancan'
gem 'country-select'
gem 'acts-as-taggable-on', '~> 2.2.2'
gem 'gem-licenses'

# js runtime for server
gem "therubyracer", :require => 'v8'

# whenever for cron
gem 'whenever', :require => false
gem 'twitter-bootstrap-rails'


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'simplecov', :require => false
  gem 'jslint_on_rails'
  gem "factory_girl_rails", "~> 4.0"
  gem 'shoulda'
  gem 'mocha'
end
