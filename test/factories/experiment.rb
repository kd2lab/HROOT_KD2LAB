FactoryGirl.define do
  factory :experiment do 
    sequence(:name) {|n| "Experiment #{n}"}
    invitation_hours 1
    invitation_size 2
  end
end
