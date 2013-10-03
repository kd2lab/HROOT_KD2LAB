namespace :customfields do
  desc "Create custom fields"
  task :create => :environment do
    Datafields.fields.each do |f|    
      begin  
        results = ActiveRecord::Base.connection.execute("ALTER TABLE users ADD "+f.name+" "+f.sqltype)
        puts "Created columm "+f.name
      rescue
        puts f.name+" already exists"
      end
    end
  end
end