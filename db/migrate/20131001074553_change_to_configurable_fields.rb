class ChangeToConfigurableFields < ActiveRecord::Migration
  def up
    # todo log necessary changes to a file
    
    add_column :users, :language, :text
    add_column :users, :begin_of_studies, :date
    add_column :users, :degree, :text
    add_column :users, :profession, :text
    add_column :users, :course_of_studies, :text
    
    # combine existing languages
    execute <<-SQL
      UPDATE users SET language = CONCAT_WS(';', lang1, lang2, lang3)
    SQL
    
    # change study begin to date
    execute <<-SQL
      UPDATE users SET begin_of_studies = CAST(CONCAT(begin_year,'-',LPAD(begin_month,2,'00'),'-01') AS DATE);
    SQL
    
    # migrate degree_id to degree
    execute <<-SQL
      UPDATE users SET degree=degree_id;
    SQL

    # migrate profession_id to profession
    execute <<-SQL
      UPDATE users SET profession=profession_id;
    SQL
    
    # migrate study_id to course_of_studies
    execute <<-SQL
      UPDATE users SET course_of_studies=study_id;
    SQL
    
    language_data = ActiveRecord::Base.connection.select_all('SELECT * FROM languages;')
    profession_data = ActiveRecord::Base.connection.select_all('SELECT * FROM professions;')
    degree_data = ActiveRecord::Base.connection.select_all('SELECT * FROM degrees;')
    study_data = ActiveRecord::Base.connection.select_all('SELECT * FROM studies;')
        
    say "Please add the following line to your initializers/fields.rb file:"
    
    say "selection :language, "+language_data.map{|l| l['id']}.to_s+", {:required => false, :multiple => true}"
    say "selection :profession, "+profession_data.map{|l| l['id']}.to_s+", {:required => false}"
    say "selection :degree, "+degree_data.map{|l| l['id']}.to_s+", {:required => false}"
    say "selection :course_of_studies, "+study_data.map{|l| l['id']}.to_s+", {:required => false}"
    
    
    say "Please add the following translations to your customfields.de.yml and customfields.en.yml:"
    say "language:"
    language_data.each do |l| 
      say "  value"+l['id'].to_s+": "+l['name']
    end
    
    say "degree:"
    degree_data.each do |l| 
      say "  value"+l['id'].to_s+": "+l['name']
    end
    
    say "profession:"
    profession_data.each do |l| 
      say "  value"+l['id'].to_s+": "+l['name']
    end
    
    say "course_of_studies:"
    study_data.each do |l| 
      say "  value"+l['id'].to_s+": "+l['name']
    end
      
    # remove old fields and tables
    remove_column :users, :degree_id
    remove_column :users, :study_id
    remove_column :users, :profession_id
    remove_column :users, :lang1
    remove_column :users, :lang2
    remove_column :users, :lang3
    remove_column :users, :begin_month
    remove_column :users, :begin_year
    
    execute "DROP TABLE studies;"
    execute "DROP TABLE professions;"
    execute "DROP TABLE languages;"
    execute "DROP TABLE degrees;"
  end

  def down
  end
end
