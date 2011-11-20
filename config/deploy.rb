# capistrano integration
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
set :rvm_ruby_string, "1.9.2@hroot"
set :use_sudo, false

set :bundle_dir, ""
set :bundle_flags, ""
require "bundler/capistrano"

set :application, "hroot"
set :repository,  "git@ingmar.net:hroot.git"

set :scm, :git

set :deploy_to, "/var/www/rails/#{application}"
set :user, "root"

server "root@lvps83-169-5-139.dedicated.hosteurope.de", :app, :web, :db, :primary => true

namespace :deploy do
  desc "Tell unicorn to restart the app."
  task :restart, :roles => :app do
    run "(test -f #{current_path}/tmp/pids/unicorn.pid && kill -s USR2 `cat #{current_path}/tmp/pids/unicorn.pid`)"
  end
  
  task :compile_assets do
    run "cd #{release_path}; RAILS_ENV=production rake assets:precompile"
  end
  
end

# whenever integration
set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { stage }
require "whenever/capistrano"


before "deploy", "deploy:restart"
after "deploy", "deploy:migrate"
after 'deploy:update_code', 'deploy:compile_assets'


