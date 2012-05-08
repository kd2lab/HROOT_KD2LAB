# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message do
    subject "MyString"
    recipient_id 1
    sender_id 1
    message "MyString"
  end
end
