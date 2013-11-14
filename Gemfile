#if RUBY_VERSION =~ /1.9/
#  Encoding.default_external = Encoding::UTF_8
#  Encoding.default_internal = Encoding::UTF_8
#end

source 'http://rubygems.org'

gem 'rails', '3.2.11'
gem 'mysql2'
gem 'haml'
gem 'sass'
gem 'unicorn'
gem 'less-rails'
gem 'coffee-script'
gem 'ledermann-rails-settings', '1.2.1', :require => 'rails-settings'
gem 'sequel'
gem 'jquery-rails', '>= 1.0.12'
gem 'will_paginate'
gem 'devise', '3.1.1'
gem 'simple_form'
gem 'event-calendar', :require => 'event_calendar'
gem 'exception_notification'
gem 'icalendar'
gem 'cancan'
#gem 'country-select'
gem 'acts-as-taggable-on', '~> 2.2.2'

# js runtime for server
gem "therubyracer", :require => 'v8'

# whenever for cron
gem 'whenever', :require => false
gem 'twitter-bootstrap-rails'


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'debugger'
  gem 'simplecov', :require => false
  gem 'jslint_on_rails'
  gem "factory_girl_rails", "~> 4.0"
  gem 'shoulda'
  gem 'mocha', :require => 'mocha/setup'
  gem 'capistrano', '~> 3.0.1'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm', '~> 0.0.3'
end

group :production do
  #gem 'pg'
end

