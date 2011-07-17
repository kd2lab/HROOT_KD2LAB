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

server "root@lvps83-169-5-139.dedicated.hosteurope.de", :app, :web, :db

namespace :deploy do
  desc "Tell unicorn to restart the app."
  task :restart, :roles => :app do
    run "(test -f #{current_path}/tmp/pids/unicorn.pid && kill -s USR2 `cat #{current_path}/tmp/pids/unicorn.pid`)"
  end
  
  desc "Compile css"
  task :compile, :roles => :app do
    run "cd #{current_path} && compass compile"
  end
end

before "deploy:restart", "deploy:compile"