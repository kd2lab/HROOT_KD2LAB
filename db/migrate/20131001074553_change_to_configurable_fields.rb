class ChangeToConfigurableFields < ActiveRecord::Migration
  def up
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
      UPDATE users SET begin_of_studies = CAST(CONCAT(`begin_year`,'-',LPAD(`begin_month`,2,'00'),'-01') AS DATE);
    SQL
    
    # migrate degree_id to degree
    execute <<-SQL
      UPDATE users SET degree=degree_id;
    SQL

    # migrate profession_id to profession
    execute <<-SQL
      UPDATE users SET degree=degree_id;
    SQL
    
    # migrate study_id to course_of_studies
    execute <<-SQL
      UPDATE users SET course_of_studies=study_id;
    SQL
    
    
    say "Please add the following line to your initializers/fields.rb file:"
    
    lang_ids = Language.all.map do |l| l.id end
    prof_ids = Profession.all.map do |l| l.id end
    degree_ids = Degree.all.map do |l| l.id end
    study_ids = Study.all.map do |l| l.id end
    
    say "selection :language, "+lang_ids.to_s+", {:required => false, :multiple => true}"
    say "selection :profession, "+prof_ids.to_s+", {:required => false}"
    say "selection :degree, "+degree_ids.to_s+", {:required => false}"
    say "selection :course_of_studies, "+study_ids.to_s+", {:required => false}"
    
    say "Please add the following translations to your customfields.de.yml and customfields.en.yml:"
    say "language:"
    Language.all.each do |l| 
      say "  value"+l.id.to_s+": "+l.name
    end
    say "degree:"
    Degree.all.each do |l| 
      say "  value"+l.id.to_s+": "+l.name
    end
    
    say "profession:"
    Profession.all.each do |l| 
      say "  value"+l.id.to_s+": "+l.name
    end
    say "course_of_studies:"
    Study.all.each do |l| 
      say "  value"+l.id.to_s+": "+l.name
    end
    
  end

  def down
  end
end
