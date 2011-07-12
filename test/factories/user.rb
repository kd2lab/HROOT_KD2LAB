Factory.define :user do |u|
  u.sequence(:email) {|n| "test#{n}@hroot.com"}
  u.password 'test123'
  u.password_confirmation 'test123'
end
