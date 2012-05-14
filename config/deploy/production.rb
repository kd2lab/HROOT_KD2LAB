## different rvm location
set :rvm_bin_path, "$HOME/.rvm/bin"
set :rvm_path, "$HOME/.rvm"

set :deploy_to, "~/projects/#{application}"
set :user, "hroot"
server "hroot@wiso-srv-webhr.wiso.uni-hamburg.de", :app, :web #, :db, :primary => true


set :deploy_via, :copy


# unicorn integration
set :unicorn_binary, "/usr/local/rvm/gems/ruby-1.9.2-p0@hroot/bin/unicorn"
set :unicorn_config, "#{current_path}/config/unicorn.rb"
set :unicorn_pid, "#{current_path}/tmp/pids/unicorn.pid"
