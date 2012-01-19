Factory.define :session do |s|
  s.sequence(:description) {|n| "Session #{n}"}
  s.needed 3
  s.time_before 0
  s.time_after 0
  s.reserve 2
end

Factory.define :future_session, :parent => :session do |s|
  s.start_at Time.zone.now + 1.days
  s.end_at Time.zone.now + 1.days + 2.hours
end

Factory.define :past_session, :parent => :session do |s|
  s.start_at Time.zone.now - 1.days
  s.end_at Time.zone.now - 1.days + 2.hours
end
