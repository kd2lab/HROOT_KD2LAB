# Learn more: http://github.com/javan/whenever

every 5.minutes do
  runner "Task.run_tasks"
end

every 1.days do
  runner "LoginCode.cleanup"  
end

# todo later: warn about incomplete sessions
#every 7.days do
  #runner "Task.send_reminders_for_incomplete_sessions"  
#end