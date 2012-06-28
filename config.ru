# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
map Hroot::Application.config.path_prefix || '/' do
  run Hroot::Application
end