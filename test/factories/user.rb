FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "test#{n}@uni-hamburg.de"}
    password '_1abcdefg'
    password_confirmation '_1abcdefg'
    firstname "john"
    lastname "smith"
    matrikel "1234"
    gender 'm'
    birthday Date.today
    country_name "Germany"
    preference 1
    role "user"
    after(:create) { |user| user.confirm!}
  end

  factory :admin, parent: :user do
    role 'admin'
  end

  factory :experimenter, parent: :user do
    role 'experimenter'
  end

end
