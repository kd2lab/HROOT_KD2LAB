FactoryGirl.define do  
  factory :session_group do
  end

  factory :future_session_group, parent: :session_group do
    ignore do
      sessions_count 2
    end
    after(:create) do |future_session_group, evaluator|
      create_list(:future_session, evaluator.sessions_count, session_group: future_session_group, experiment: future_session_group.experiment)
    end
  end
end
