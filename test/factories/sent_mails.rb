# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sent_mail do
    subject "MyString"
    message "MyText"
    from "MyString"
    to "MyString"
    message_type 1
    user_id 1
    experiment_id 1
    sender_id 1
    session_id 1
  end
end
