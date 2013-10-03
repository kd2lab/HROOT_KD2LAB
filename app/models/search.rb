class SearchField
  attr_accessor :name
  attr_accessor :locals
  
  def initialize(name = 'undefined', locals = {})
    @name = name
    @locals = locals
  end
  
  def partial
    "shared/search/#{self.class.to_s.gsub('SearchField','').underscore}"
  end
  
  def partial_locals
    locals
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
    valid_values = locals[:values] || {}
    
    # sql condition for select fields
    condition = ""
    
    if locals[:multiple]
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
    if search[:op] == 'without' && !condition.blank?
      condition = "(NOT(#{condition}) OR users.#{name} IS NULL)"
    else
      condition
    end
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
    # todo sanitize tag value
    res = search.map do |row|
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
        
      if row[:op] == 'at_least'
        experiment_tag_subquery += " >= #{row[:count].to_i}"
      elsif row[:op] == 'at_most'
        experiment_tag_subquery += " <= #{row[:count].to_i}"
      else
        experiment_tag_subquery += "ERRROR todo"
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
        # todo maybe we can simplify this
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

class Search
  @@fields = {}
  
  # returns the partial for a specific search field
  def self.partial_for(name)
    if @@fields[name]
      @@fields[name].partial
    else
      "shared/search/undefined"
    end
  end

  # returns the local variables to pass to partial rendering
  def self.partial_locals_for(name)
    if @@fields[name]
      @@fields[name].partial_locals
    else
      {}
    end
  end
    
  # adds a search field to the list
  def self.add(field)
    @@fields[field.name] = field
  end  
    
  # takes a hash of search values and requests the sql conditions from the corresponding searchfield objects  
  def self.where_conditions(search_values)
    result = []
    
    # default: do not show deleted users
    search_values = search_values.dup
    search_values[:deleted] = {:value => 0} unless search_values.has_key?(:deleted)
    
    search_values.each do |key, val|
      result << @@fields[key.to_sym].where_conditions(val) if @@fields[key.to_sym]
    end
    
    result.compact
  end  
    
  # creates the where, select and join parts of the full query
  def self.create_sql_parts(search, options)
    where = where_conditions(search)
    joins = []
    select = ['DISTINCT users.*']
    experiment = options[:experiment]
    
    # include / exclude participants in experiment
    if experiment
      joins << "LEFT JOIN participations p ON p.user_id = users.id AND p.experiment_id = #{experiment.id} "
    
      if options[:exclude]
        where << "p.id IS NULL"
      else
        where << "p.id IS NOT NULL"
        
        # limit to users of a certain session
        if options[:session]
          # load specific given session
          joins << "JOIN (sessions sj JOIN session_participations sps ON sj.id = sps.session_id AND sj.id = #{options[:session].to_i}) ON sj.experiment_id = #{experiment.id} AND sps.user_id = users.id "         
          select << "sps.reminded_at, sj.start_at as session_start_at, sj.id as session_id, p.invited_at, sps.showup as session_showup, sps.noshow as session_noshow, sps.participated as session_participated"
        else
          # or load session_participation and join reference sessions
          joins << "LEFT JOIN (sessions sj JOIN session_participations sps ON sj.id = sps.session_id) ON sj.experiment_id = #{experiment.id} AND sj.id = sj.reference_session_id AND sps.user_id = users.id "         
          select << "sps.reminded_at, sj.start_at as session_start_at, sj.id as session_id, p.invited_at, sps.showup as session_showup, sps.noshow as session_noshow, sps.participated as session_participated"
        end

        # only select users with a successful participation
        # this filter only makes sense, when we select participants of an experiment
        if search[:participation]
          where << "sps.participated = 1" if search[:participation][:value] == '1'
          where << "sps.session_id > 0" if search[:participation][:value] == '2'
          where << "(sps.session_id IS NULL)" if search[:participation][:value] == '3'
          
          if search[:participation][:value] == '4'
            where << "sps.session_id > 0 AND sj.end_at > NOW()"
          end
        end  
      end
    end
    
    return select, joins, where
  end
    
  # assembles the full query  
  def self.create_query(search, options)
    select, joins, where = create_sql_parts(search, options)
    
    sort_column = options[:sort_column] || 'lastname'
    sort_direction = options[:sort_direction] || 'ASC'
    
    <<EOSQL
        SELECT #{select.join(',')}
        FROM users
        #{joins.join(' ')}
        #{'WHERE ' + where.join(' AND ') unless where.blank?} 
        ORDER BY #{sort_column + ' ' + sort_direction}   
EOSQL
  end
  
  # assembles a full count query
  def self.create_count_query(search, options)
    select, joins, where = create_sql_parts(search, options)
    
    <<EOSQL
        SELECT count(DISTINCT users.id)
        FROM users
        #{joins.join(' ')}
        #{'WHERE ' + where.join(' AND ') unless where.blank?} 
EOSQL
  end  
  
  # finds  a full list of user objects
  def self.search search, options = {}
    Search.init
    User.find_by_sql(create_query(search.symbolize_keys, options))
  end
  
  # finds a full list of user ids
  def self.search_ids search, options = {}
    Search.init
    sql = create_query(search.symbolize_keys, options)
    result = ActiveRecord::Base.connection.execute("SELECT id FROM ("+sql+") as id_table;")
    result.collect{ |res| res[0] }
  end
  
  # finds a list of users based on the pagination settings
  def self.paginate params, options = {}
    Search.init
    search = params[:search].symbolize_keys
    count = User.count_by_sql(create_count_query(search, options))

    # paging
    page = (params[:page] || 1).to_i
    if (count < (page-1)*50) 
      # reset page, if not enough results
      page = 1
    end

    sql = create_query(search, options) + " LIMIT 50 OFFSET "+((page-1)*50).to_s
    objects = User.find_by_sql(sql)
    
    return WillPaginate::Collection.create(page,50) do |pager|    
      pager.replace(objects)
      pager.total_entries = count
    end
    
    # todo include counting optimization again but tink about it more
    # if search && ( search.keys.count > 0 || (options && options[:experiment]))
#       count = User.count_by_sql(User.create_filter_sql(params, options, true))
#     elsif options && options[:include_deleted_users]
#       count = User.count
#     else  
#       count = User.where('deleted=0').count
#     end
#     
    
  end    
    
    
    
  def self.init
    # standard search fields
    add FulltextSearchField.new(:fulltext)
    add SelectionSearchField.new(:role, :values => User.roles.map{|r| [I18n.t("search.selections.role.#{r}"), r]})
    add DeletedSearchField.new(:deleted, :values => {I18n.t('search.selections.deleted.hide_deleted') => '', I18n.t('search.selections.deleted.show_deleted') => 'show'})
    add IntegerSearchField.new(:noshow_count, :range => 0..(User.maximum(:noshow_count) || 10))
    add IntegerSearchField.new(:participations_count, :range => 0..(User.maximum(:participations_count) || 10))
    add TagsSearchField.new(:tags)
    add ExperimentsSearchField.new(:experiments)
    
    Datafields.fields.each do |field|
      add field.search_field
    end
  end    
end