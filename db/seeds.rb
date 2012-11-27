# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# create initial admin user
u = User.new(:email => "admin@domain.net", :password => "admin_12345", :password_confirmation => "admin_12345", :firstname => "admin", :lastname => "admin", :role => 'admin', :matrikel => "admin")
u.admin_update = true
u.skip_confirmation!
u.calendar_key = SecureRandom.hex(16)
u.save(:validate => false)
