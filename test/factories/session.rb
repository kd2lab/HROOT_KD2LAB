FactoryGirl.define do  
  factory :session do
    sequence(:description) {|n| "Session #{n}"}
    needed 3
    time_before 0
    time_after 0
    reserve 2
  end
  
  factory :future_session, parent: :session do
    start_at Time.zone.now + 1.days
    end_at Time.zone.now + 1.days + 2.hours
  end
  
  factory :past_session, parent: :session do
    start_at Time.zone.now - 1.days
    end_at Time.zone.now - 1.days + 2.hours
  end
end
