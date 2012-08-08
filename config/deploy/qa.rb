set :deploy_to, "/var/www/rails/#{application}"
set :user, "root"
server "root@lvps83-169-5-139.dedicated.hosteurope.de", :app, :web, :db, :primary => true
set :rails_env, "qa"

# unicorn integration
set :unicorn_binary, "/usr/local/rvm/gems/ruby-1.9.2-p0@hroot/bin/unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"
