worker_processes 2
pid         "/var/www/rails/hroot/shared/pids/unicorn.pid"
stderr_path "/var/www/rails/hroot/shared/log/unicorn.log"
stdout_path "/var/www/rails/hroot/shared/log/unicorn.log"
working_directory "/var/www/rails/hroot/current"
listen 8090
preload_app true
HttpRequest::DEFAULTS["rack.url_scheme"] = "https"

before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.

  old_pid = RAILS_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end