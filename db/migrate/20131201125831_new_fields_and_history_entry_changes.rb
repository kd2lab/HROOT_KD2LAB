# encoding: utf-8

class NewFieldsAndHistoryEntryChanges < ActiveRecord::Migration
  def up
    add_column :session_participations, :seat_nr, :integer
    add_column :session_participations, :payment, :decimal, precision: 8, scale: 2
    add_column :users, :comment, :text
    add_column :experiments, :refkey, :string
    change_column :users, :experience, :integer
    add_column :participations, :added_by_public_key, :integer, :default => 0
    
    # Setup counter cache
    Experiment.reset_column_information
    Experiment.all.each do |e|
      Experiment.reset_counters(e.id, :participations)
    end

    # create a refkey for each experiment
    Experiment.all.each do |e| 
      e.generate_token
      e.save
    end


    add_column :history_entries, :search, :text
    HistoryEntry.all.each do |h|
      search = {}
      filter = JSON.parse(h.filter_settings)

      newbegin = {}
      
      if (filter.has_key?("begin_von_year") && filter.has_key?("begin_von_month"))
        if !filter["begin_von_year"].blank?
          newbegin["from"] = "%04d-%02d-%02d" % [filter["begin_von_year"].to_i, filter["begin_von_month"].to_i, 1]
        end
      end

      if (filter.has_key?("begin_bis_year") && filter.has_key?("begin_bis_month"))
        if !filter["begin_bis_year"].blank?
          newbegin["to"] = "%04d-%02d-%02d" % [filter["begin_bis_year"].to_i, filter["begin_bis_month"].to_i, 1]
        end
      end
      
      if (filter.has_key?("begin_von_year") && filter.has_key?("begin_von_month"))
        newbegin["from"] = "%04d-%02d-%02d" % [filter["begin_von_year"].to_i, filter["begin_von_month"].to_i, 1]
        search["begin_of_studies"] = newbegin
      end
      
      
      search["begin_of_studies"] = newbegin if !newbegin.keys.empty?
    
      # text search
      if filter.has_key?("search")
        search["fulltext"] = filter["search"] unless filter["search"].blank?
      end 
      
      # role
      if filter.has_key?("role") 
        if filter["role"] == "user"
          search["role"] = { "value" => filter["role"] } 
        else
          @log += "Warning 1 #{filter['role']}";
        end
      end  

      # noshow
      if filter.has_key?("noshow") 
        search["noshow_count"] = {"op" => filter["noshow_op"], "value" => filter["noshow"]}
      end        
      
      # participated
      if filter.has_key?("participated") 
        search["participations_count"] = {"op" => filter["participated_op"], "value" => filter["participated"]}
      end        
      
      if filter.has_key?("study")
        mapping = {
          "only" => "1",
          "without" => "2",
          "Nur"  => "1",
          "Ohne" => "2",
          "1" => "1",
          "2" => "2"
        }
        
        search["course_of_studies"] = {"value" => filter["study"], "op" => mapping[filter["study_op"]]}
        
      end 
      
      if filter.has_key?("degree")
        mapping = {
          "only" => "1",
          "without" => "2",
          "Nur"  => "1",
          "Ohne" => "2",
          "1" => "1",
          "2" => "2"
        }
        
        search["degree"] = {"value" => filter["degree"], "op" => mapping[filter["degree_op"]]}
      end 
      
      #participation
      if filter.has_key?("participation")
        search["participation"] = {"value" => filter["participation"]}
      end
      
      # filter for tags
      search["gender"] = {"value" => filter["gender"]} if filter.has_key?("gender")
      
      
      # filter for tags
      if filter.has_key?("exp_tag_op1") 
        search["tags"] = []
        mapping = {
          "Höchstens"  => "<=",
          "Mindestens" => ">=",
          "At most"   => ">=",
          "At least"    => "<=",
          "1" => ">=",
          "2" => "<="
        }
        
        filter['exp_tag_op1'].each_with_index do |op1, i|          
          obj = {"op" => mapping[filter['exp_tag_op1'][i]], "count" => filter['exp_tag_op2'][i], "tag" => filter['exp_tag'+i.to_s] }
          search["tags"] << obj unless obj["tag"].blank?
        end
      end
      
      if filter.has_key?("experiment")
        mapping = {
          "die zu einem der folgenden Experimente zugeordnet sind" => "1",
          "die zu allen der folgenden Experimente zugeordnet sind" => "2",
          "die zu keinem der folgenden Experimente zugeordnet sind" => "3",
          "die an mindestens einer Session eines der folgenden Experimente teilgenommen haben" => "4",
          "die an mindestens einer Session von jedem der folgenden Experimente teilgenommen haben" => "5",
          "die an keiner Session der folgenden Experimente teilgenommen haben" => "6",
          "who are assigned to one of the following experiments" => "1",
          "who are assigned to all of the following experiments" => "2",
          "who are not assigned to any of the following experiments" => "3",
          "who have participated in at least one session of one of the following experiments" => "4",
          "who have participated in at least one session of all of the following experiments" => "5",
          "who have not participated in any session of the following experiments" => "6",
          "1" => "1",
          "2" => "2",
          "3" => "3",
          "4" => "4",
          "5" => "5",
          "6" => "6"
        }
      
        search["experiments"] = {"op" => mapping[filter["exp_op"]], "value" => filter["experiment"] }
      end
      
      h.update_attribute(:search, search.to_json)
    end 

    # todo later uncomment this
    #remove_column :history_entries, :filter_settings
  end

  def down
    remove_column :history_entries, :search
    
  end
end
