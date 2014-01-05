class SearchField
  attr_accessor :name
  attr_accessor :options
  
  def initialize(name = 'undefined', options = {})
    @name = name
    @options = options
  end
  
  def partial
    "shared/search/#{self.class.to_s.gsub('SearchField','').underscore}"
  end
  
  def where_conditions(x)
    "where_conditions from #{name}"
  end
end

class FulltextSearchField < SearchField
  def where_conditions(search)
    wildcard = "%#{search}%"
    ActiveRecord::Base.send(:sanitize_sql_array, ['(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)', wildcard, wildcard, wildcard])
  end
end
  
class SelectionSearchField < SearchField
  def where_conditions(search)
    # sql condition for select fields
    condition = ""
    
    if options[:store_multiple]
      condition = if search[:value].class == Array
        '('+search[:value].map{|s| "LOCATE('#{s}', #{name})>0"}.join(' OR ')+')'
      else
        "LOCATE('#{search[:value].to_i}', #{name})>0"
      end 
    else
      condition = if search[:value].class == Array
        "users.#{name} IN (#{search[:value].map{|v| "'#{v}'"}.join(',')})"
      else
        ActiveRecord::Base.send(:sanitize_sql_array, ["users.#{name} = ?", search[:value]])
      end 
    end    
    
    # allow operator to negate query
    if search[:op] == "2" && !condition.blank?
      condition = "(NOT(#{condition}) OR users.#{name} IS NULL)"
    else
      condition
    end
  end
end

class ParticipationSearchField < SelectionSearchField
  def where_conditions(search)
  end
  
  def partial
    "shared/search/selection"
  end
end

class DeletedSearchField < SearchField
  def where_conditions(search)
    "users.deleted=0" unless search && search[:value] == "show"  
  end  
  
  def partial
    "shared/search/selection"
  end
end

class IntegerSearchField < SearchField
  def where_conditions(search)
    # sanitize
    search_op = if ['<=', '>'].include?(search[:op]) then search[:op] else '<' end

    # sql condition for int fields
    "users.#{name} #{search[:op]} #{search[:value].to_i}"
  end  
end

class DateSearchField < SearchField
  def where_conditions(search)
    # sanitize: parse date
    conditions = []
  
    conditions << ActiveRecord::Base.send(:sanitize_sql_array, ["users.#{name} >= ?", Date.parse(search[:from])]) rescue false
    conditions << ActiveRecord::Base.send(:sanitize_sql_array, ["users.#{name} <= ?", Date.parse(search[:to])]) rescue false
  
    # sql condition for date fields
    '('+conditions.join(' AND ')+')' if conditions.length > 0
  end  
end

class TagsSearchField < SearchField
  def where_conditions(search)
    # todo later sanitize tag value
    res = search.select{|row| !row[:tag].blank?}.map do |row|
      experiment_tag_subquery = <<EOSQL
        (SELECT 
          COUNT(session_participations.id)
         FROM session_participations, sessions, experiments, taggings, tags 
         WHERE 
           session_participations.participated = 1 AND
           session_participations.user_id = users.id AND 
           session_participations.session_id = sessions.id AND
           sessions.experiment_id = experiments.id AND
           experiments.id = taggings.taggable_id AND
           taggings.tag_id = tags.id AND 
           tags.name LIKE "#{row[:tag]}")
EOSQL
        
      if row[:op] == '>='
        experiment_tag_subquery += " >= #{row[:count].to_i}"
      elsif row[:op] == '<='
        experiment_tag_subquery += " <= #{row[:count].to_i}"
      else
        experiment_tag_subquery += " <= 0"
      end  
      experiment_tag_subquery
    end
          
    if res.length > 0
      "(#{res.join(' AND ')})"
    else
      ''
    end
  end  
end

class ExperimentsSearchField < SearchField
  def where_conditions(search)
    # sanitize ids
    if !search[:value].blank?
      ids = search[:value].map(&:to_i)

      # at least one ...
      case search[:op].to_i
      when 1
        # only users who are on the participant list of some experiments
        where = "(SELECT COUNT(participations.id) FROM participations WHERE user_id = users.id AND participations.experiment_id IN (#{ids.join(',')})) > 0"
      when 2
        # only users who are on the participant list of all these experiments
        where = "(SELECT COUNT(participations.id) FROM participations WHERE user_id = users.id AND participations.experiment_id IN (#{ids.join(',')})) = #{ids.count}"
      when 3
        # only users who are on the participant list of all these experiments
        where = "(SELECT COUNT(participations.id) FROM participations WHERE user_id = users.id AND participations.experiment_id IN (#{ids.join(',')})) = 0"
      when 4
        where = "(SELECT COUNT(sp.id) FROM sessions s, session_participations sp WHERE sp.participated = 1 AND sp.user_id = users.id AND s.id = sp.session_id AND s.experiment_id IN (#{ids.join(',')})) > 0"
      when 5
        where = "(SELECT COUNT(sp.id) FROM sessions s, session_participations sp WHERE sp.participated = 1 AND sp.user_id = users.id AND s.id = sp.session_id AND s.experiment_id IN (#{ids.join(',')})) = #{ids.count}"
      when 6
        where = "(SELECT COUNT(sp.id) FROM sessions s, session_participations sp WHERE sp.participated = 1 AND sp.user_id = users.id AND s.id = sp.session_id AND s.experiment_id IN (#{ids.join(',')})) = 0"
      end
  
      where
    end
  end  
end