# encoding:utf-8

class HistoryEntry < ActiveRecord::Base
  def to_s
    case action
    when "add_filtered_users", "add_selected_users"
      I18n.t('filter_summary.add_text', :count => user_count)
    when "remove_filtered_users", "remove_selected_users"
      I18n.t('filter_summary.remove_text', :count => user_count)
    when "added_by_public_key"
      I18n.t('filter_summary.add_public_key_text')
    end
  end
  
  def is_adding_entry?
    return action == "add_selected_users" || action == "add_filtered_users" || action=='added_by_public_key'
  end
  
  def arr_user_ids
    JSON.parse(user_ids)
  end
  
  def users
    User.where(:id => arr_user_ids).order(:lastname)
  end
  
  def self.get_filter_setting_string (filter)
    report = []
    
    CUSTOM_FIELDS.fields.each do |field|
      if filter.keys.include? field.name
        search = filter[field.name]
        case field.class.to_s
        when "SelectionField"
          #report << search
          if field.options[:translate]
            #report << "translated"
            vals = []
            field.values.each do |val|
              varname = if val.kind_of? Integer then "value"+val.to_s else val end
              if search["value"].include?(val.to_s)
                vals << I18n.t('customfields.'+field.name+'.'+varname)
              end    
            end    
          else
            vals = search["value"]
          end  
          if search["op"].to_i == 1
            report << I18n.t('search.titles.'+field.name)+": "+I18n.t('search.selections.only')+ " " + vals.join(', ')
          elsif search["op"].to_i == 2
            report << I18n.t('search.titles.'+field.name)+": "+I18n.t('search.selections.without')+ " " + vals.join(', ')
          else
            report << I18n.t('search.titles.'+field.name)+": "+I18n.t('search.selections.only')+ " " + vals.join(', ')
          end
        when "DateField"
          str = I18n.t('search.titles.'+field.name)+": "
          if (search['from'])
            str += I18n.t('filter_summary.from')+" #{search['from']} "
          end

          if (search['to'])
            str += I18n.t('filter_summary.to')+" #{search['to']}"
          end

          report << str
        else
          report << "Display for #{field.class} not implemented yet"
        end
      end
    end

    
    # search
    unless filter['fulltext'].blank?
      report << "#{I18n.t('filter_summary.search')} '#{filter['fulltext']}'"
    end
    
    # noshow
    if filter['noshow_count']
      if ["<=", ">"].include?(filter['noshow_count']['op'])
        report << "#{I18n.t('filter_summary.noshow_count')} #{filter['noshow_count']['op']} #{filter['noshow_count']['value'].to_i}"
      end
    end
 
    if filter['participations_count']
      if ["<=", ">"].include?(filter['participations_count']['op'])
        report << "#{I18n.t('filter_summary.participations_count')} #{filter['participations_count']['op']} #{filter['participations_count']['value'].to_i}"
      end
    end

    if filter['tags']
      filter['tags'].each do |tag|
        report << "Tag #{tag['tag']}: #{tag['op']} #{tag['count']}"
      end
    end  
    
    #experiments
    # if the user even has selected some experiments    
    if filter['experiments']
      ids = filter['experiments']['value'].map(&:to_i)
      names = Experiment.where(:id => ids).map(&:name).join(', ')
      report << case filter['experiments']['op'].to_i
        when 1
          "#{I18n.t('filter_summary.exp1')} #{names}"
        when 2
          "#{I18n.t('filter_summary.exp2')} #{names}"      
        when 3
          "#{I18n.t('filter_summary.exp3')} #{names}"      
        when 4
          "#{I18n.t('filter_summary.exp4')} #{names}"      
        when 5
          "#{I18n.t('filter_summary.exp5')} #{names}"      
        when 6
          "#{I18n.t('filter_summary.exp6')} #{names}"      
      end
    end
    
    report 
  end
end
