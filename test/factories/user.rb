Factory.define :user do |u|
  u.sequence(:email) {|n| "test#{n}@hroot.com"}
  u.password '_1abcdefg'
  u.password_confirmation '_1abcdefg'
  u.firstname "john"
  u.lastname "smith"
  u.matrikel "1234"
  u.gender 'm'
  u.birthday Date.today
  u.role "user"
  u.after_create { |user| user.confirm!}
end

Factory.define :admin, :parent => :user do |u|
  u.role 'admin'
end

Factory.define :experimenter, :parent => :user do |u|
  #u.after_create { |user| user.has_role!(:admin) }
  u.role 'experimenter'
end