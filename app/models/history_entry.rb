# encoding:utf-8

class HistoryEntry < ActiveRecord::Base
  def to_s
    case action
    when "add_filtered_users", "add_selected_users"
      I18n.t('filter_summary.add_text', :count => user_count)
    when "remove_filtered_users", "remove_selected_users"
      I18n.t('filter_summary.remove_text', :count => user_count)
    end
  end
  
  def is_adding_entry?
    return action == "add_selected_users" || action == "add_filtered_users"
  end
  
  def arr_user_ids
    JSON.parse(user_ids)
  end
  
  def users
    User.where(:id => arr_user_ids).order(:lastname)
  end
  
  def self.get_filter_setting_string (filter)
    report = []
    
    # search
    unless filter['search'].blank?
      report << "#{I18n.t('filter_summary.search')} '#{filter['search']}'"
    end
    
    # gender
    if ['f', 'm', '?'].include?(filter['gender'])
      report << "#{I18n.t('filter_summary.gender')}=#{filter['gender']}"
    end
        
    # preference
    if [1,2].include?(filter['preference'].to_i)
      pref_description = ["", I18n.t('filter_summary.only_with_presence_preference'), I18n.t('filter_summary.only_with_online_preference')][filter['preference'].to_i]
      report << "#{I18n.t('filter_summary.preference')}: #{pref_description}"
    end
    
    # noshow
    if ["<=", ">"].include?(filter['noshow_op'])
      report << "#{I18n.t('filter_summary.noshow_count')} #{filter['noshow_op']} #{filter['noshow'].to_i}"
    end
    
    # successful participations
    if ["<=", ">"].include?(filter['participated_op'])
      report << "#{I18n.t('filter_summary.participation_count')} #{filter['participated_op']} #{filter['participated'].to_i}"
    end
        
    #studienbeginn
    sbegin = []
    if (1..12).include?(filter['begin_von_month'].to_i) && filter['begin_von_year'].to_i > 1990
      sbegin << "#{I18n.t('filter_summary.begin_after')} #{filter['begin_von_month'].to_i}/#{filter['begin_von_year'].to_i}"
    end

    if (1..12).include?(filter['begin_bis_month'].to_i) && filter['begin_bis_year'].to_i > 1990
      sbegin << "#{I18n.t('filter_summary.begin_before')} #{filter['begin_bis_month'].to_i}/#{filter['begin_bis_year'].to_i}"
    end
    
    if sbegin.length > 0
      report << sbegin.join(' '+I18n.t('filter_summary.and') +' ')
    end
  
    # birthday
    sbirthday = []
    if (1..12).include?(filter['birthday_von_month'].to_i) && filter['birthday_von_year'].to_i > 1900
      sbirthday << "#{I18n.t('filter_summary.birthday_after')} #{filter['birthday_von_month'].to_i}/#{filter['birthday_von_year'].to_i}"
    end

    if (1..12).include?(filter['birthday_bis_month'].to_i) && filter['birthday_bis_year'].to_i > 1900
      sbirthday << "#{I18n.t('filter_summary.birthday_before')} #{filter['birthday_bis_month'].to_i}/#{filter['birthday_bis_year'].to_i}"
    end
    
    if sbirthday.length > 0
      report << sbirthday.join(' '+I18n.t('filter_summary.and') +' ')
    end
      
    # external experience
    case filter['experience']
    when "0"
      report << "#{I18n.t('filter_summary.without_experienced')}"
    when "1"
      report << "#{I18n.t('filter_summary.with_experienced')}"
    end
    
    # study 
    if filter['study']
      if filter['study_op'].to_i == 2
        s = " #{I18n.t('filter_summary.not_study')}" 
      else
        s = "#{I18n.t('filter_summary.study')}"
      end
      
      report << s + Study.where(:id => filter['study'].map(&:to_i)).map(&:name).join(', ')
    end

    # degree
    if filter['degree']
      if filter['degree_op'].to_i == 2
        s = " #{I18n.t('filter_summary.not_degree')}" 
      else
        s = "#{I18n.t('filter_summary.degree')}"
      end

      report << s + Degree.where(:id => filter['degree'].map(&:to_i)).map(&:name).join(', ')
    end
    
    # language
    if filter['language']
      s = "#{I18n.t('filter_summary.language')}"
      report << s + Language.where(:id => filter['language'].map(&:to_i)).map(&:name).join(', ')
    end
    
    
    #experiment tags
    filter['exp_tag_count'].to_i.times do |i|
      if filter["exp_tag#{i}"].length > 0
        s = filter["exp_tag#{i}"]
        
        
        
        if filter['exp_tag_op1'][i].to_i == 1
          s += " >= #{filter["exp_tag_op2"][i].to_i}"
        elsif filter['exp_tag_op1'][i].to_i == 2
          s += " <= #{filter["exp_tag_op2"][i].to_i}"
        end
        report << s
      end  
    end
    
    #experiments
    # if the user even has selected some experiments    
    if filter['experiment']
      ids = filter['experiment'].map(&:to_i)
      names = Experiment.where(:id => ids).map(&:name).join(', ')
      report << case filter['exp_op'].to_i
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
