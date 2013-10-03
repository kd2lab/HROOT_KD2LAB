namespace :hroot do
  desc "task to help with database changes"
  task :adaptdb => :environment do
    #ids_to_delete = ActiveRecord::Base.connection.execute(sql).collect{ |res| res[0]
    
    puts "------------------------\n"
    puts "Please put the following keys in the file customfields.de.yml and a translation to the file customfield.en.yml:\n\n"
    puts "de:"
    puts "  customfields:"
    
    puts "    language:"
    langs = ActiveRecord::Base.connection.execute("select id, name from languages")
    langs.each do |row|
      puts "      value#{row[0]}: #{row[1]}"
    end
    
    puts "    profession:"
    professions = ActiveRecord::Base.connection.execute("select id, name from professions")
    professions.each do |row|
      puts "      value#{row[0]}: #{row[1]}"
    end
    
    puts "    course_of_studies:"
    studies = ActiveRecord::Base.connection.execute("select id, name from studies")
    studies.each do |row|
      puts "      value#{row[0]}: #{row[1]}"
    end
    
    puts "    degree:"
    degrees = ActiveRecord::Base.connection.execute("select id, name from degrees")
    degrees.each do |row|
      puts "      value#{row[0]}: #{row[1]}"
    end




    puts "\n\n------------------------\n"
    puts "Please check, if the following lines are present in the file config/initializers/fields.rb\n\n"
    puts "selection :language, [#{langs.map{|l| l[0]}.join(', ')}], {:required => false, :multiple => true}, {:search_multiple => false, :operator => true}"
    puts "selection :profession, [#{professions.map{|l| l[0]}.join(', ')}], {:required => false}"
    puts "selection :course_of_studies, [#{studies.map{|l| l[0]}.join(', ')}], {:required => false}, {:search_multiple => true, :operator => true}"
    puts "selection :degree, [#{degrees.map{|l| l[0]}.join(', ')}], {:required => false}, {:search_multiple => true, :operator => true}"
    
    puts "\n\n------------------------\n"
    puts "When you have applied the changes, you can run the following queries in your database:\n"
    
    puts <<-EOSQL

    ALTER TABLE users CHANGE degree_id degree INT;
    ALTER TABLE users CHANGE study_id course_of_studies INT;
    ALTER TABLE users CHANGE profession_id profession INT;
    ALTER TABLE users ADD COLUMN language TEXT;
    ALTER TABLE users ADD COLUMN begin_of_studies DATE;
     
    UPDATE users SET language = CONCAT_WS(',', CONCAT('\'', lang1,'\''),CONCAT('\'', lang2,'\''),CONCAT('\'', lang3,'\'') );
    UPDATE users SET begin_of_studies = CONCAT_WS('-', begin_year, LPAD(begin_month, 2, '00'), '01') WHERE begin_year > 0 AND begin_month > 0;
    
    ALTER TABLE users DROP lang1;
    ALTER TABLE users DROP lang2;
    ALTER TABLE users DROP lang3;
    ALTER TABLE users DROP cellphone;
    ALTER TABLE users DROP sms_activated;
    ALTER TABLE users DROP begin_month;
    ALTER TABLE users DROP begin_year;

    
    DROP TABLE degrees;
    DROP TABLE professions;
    DROP TABLE languages;
    DROP TABLE studies;
EOSQL
  
        
    #Datafields.fields.each do |f|    
    #  begin  
    #    results = ActiveRecord::Base.connection.execute("ALTER TABLE users ADD "+f.name+" "+f.sqltype)
    #    puts "Created columm "+f.name
    #  rescue
    #    puts f.name+" already exists"
    #  end
    #end
  end
end