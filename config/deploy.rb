# rvm capistrano integration
$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
require "rvm/capistrano"
set :rvm_ruby_string, "1.9.2@hroot"
set :use_sudo, false

#rvm bundler integration
set :bundle_dir, ""
set :bundle_flags, ""
require "bundler/capistrano"

# multistage integration
set :stages, %w(production staging)
set :default_stage, "staging"
require 'capistrano/ext/multistage'


set :application, "hroot"
set :repository,  "git@ingmar.net:hroot.git"
set :scm, :git



namespace :deploy do
  task :start, :roles => :app, :except => { :no_release => true } do 
    run "cd #{current_path} && #{try_sudo} #{unicorn_binary} -c #{unicorn_config} -E #{rails_env} -D"
  end
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "#{try_sudo} kill `cat #{unicorn_pid}`"
  end
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s QUIT `cat #{unicorn_pid}`"
  end
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} kill -s USR2 `cat #{unicorn_pid}`"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    start
  end
end

namespace :deploy do
  #desc "Tell unicorn to restart the app."
  #task :restart, :roles => :app do
  #  run "(test -f #{current_path}/tmp/pids/unicorn.pid && kill -s USR2 `cat #{current_path}/tmp/pids/unicorn.pid`)"
  #end
  
  task :compile_assets do
    run "cd #{release_path}; RAILS_ENV=production rake assets:precompile"
  end
  
end

after 'deploy:update_code', 'deploy:symlink_db'

namespace :deploy do
  desc "Symlinks the database.yml"
  task :symlink_db, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/database.yml #{release_path}/config/database.yml"
  end
  
  desc "Symlinks the unicorn configuration"
  task :symlink_unicorn, :roles => :app do
    run "ln -nfs #{deploy_to}/shared/config/unicorn.rb #{release_path}/config/unicorn.rb"
  end
end

# whenever integration
set :whenever_command, "bundle exec whenever"
#set :whenever_environment, defer { stage }
require "whenever/capistrano"

#before "deploy", "deploy:stop"
after "deploy", "deploy:migrate"
after 'deploy:update_code', 'deploy:compile_assets'
after 'deploy:update_code', 'deploy:symlink_db'
after 'deploy:update_code', 'deploy:symlink_unicorn'

#after "deploy", "deploy:start"


