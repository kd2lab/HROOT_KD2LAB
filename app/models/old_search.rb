module OldSearch
  @@fields = [] 
  
  # any method placed here will apply to classes, like Hickwall
  #def acts_as_something
  #  send :include, InstanceMethods
  #end
 
  #module InstanceMethods
  #  # any method placed here will apply to instances, like @hickwall
  #end
  
  def search_fields
    @@fields
  end
  
  def search_fields_without(fields)
    @@fields.reject{|f| fields.include?(f[:name])}
  end
  
  def add name, type, data_options={}, display_options={}
    # ensure defaults
    display_options[:multiple] = true if display_options[:multiple].nil?
    display_options[:value_translation] = true if display_options[:value_translation].nil?
    
    @@fields << {:name => name.to_s, :type => type, :data_options => data_options, :display_options => display_options}
  end
  
  def get_where(fields, search_values)
    # set default for deleted users
    search_values[:deleted] = {:value => "hide"} unless search_values.has_key?(:deleted)
    
    where = fields.map do |field|
      search = search_values[field[:name].to_sym]
      if search
        case field[:data_options][:sql_handler] || field[:type]
        when :none
        when :begin_of_studies
          # sanitize: parse date
          conditions = []
        
          conditions << ActiveRecord::Base.send(:sanitize_sql_array, ["STR_TO_DATE(CONCAT(begin_year,'-',LPAD(begin_month,2,'00'),'-','01'), '%Y-%m-%d') >= ?", Date.parse(search[:from])]) rescue false
          conditions << ActiveRecord::Base.send(:sanitize_sql_array, ["STR_TO_DATE(CONCAT(begin_year,'-',LPAD(begin_month,2,'00'),'-','01'), '%Y-%m-%d') <= ?", Date.parse(search[:to])]) rescue false
        
          # sql condition for date fields
          '('+conditions.join(' AND ')+')' if conditions.length > 0
        when :text
          wildcard = "%#{search}%"
          ActiveRecord::Base.send(:sanitize_sql_array, ['(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)', wildcard, wildcard, wildcard])
        when :integer
          # sanitize
          search_op = if ['<=', '>'].include?(search[:op]) then search[:op] else '<' end
        
          # sql condition for int fields
          "users.#{field[:name]} #{search[:op]} #{search[:value].to_i}"
        when :selection
          # todo sanitize
          # grab all valid submitted values
          valid_values = field[:data_options][:values] || {}
    
          # sql condition for select fields
          condition = if search[:value].class == Array
            "users.#{field[:name]} IN (#{search[:value].map{|v| "'#{v}'"}.join(',')})"
          else
            ActiveRecord::Base.send(:sanitize_sql_array, ["users.#{field[:name]} = ?", search[:value]])
          end 
          
          # allow operator to negate query
          if search[:op] == 'without'
            condition = "(NOT(#{condition}) OR users.#{field[:name]} IS NULL)"
          else
            condition
          end
        when :tags
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
        when :experiments
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
        when :date
          # sanitize: parse date
          conditions = []
        
          conditions << ActiveRecord::Base.send(:sanitize_sql_array, ["users.#{field[:name]} >= ?", Date.parse(search[:from])]) rescue false
          conditions << ActiveRecord::Base.send(:sanitize_sql_array, ["users.#{field[:name]} >= ?", Date.parse(search[:to])]) rescue false
        
          # sql condition for date fields
          '('+conditions.join(' AND ')+')' if conditions.length > 0
        when :deleted
          # exclude deleted users unless otherwise requested
          "users.deleted=0" unless search && search[:value] == "show"  
        end
      end
    end
    
    where.compact
  end  
    
  def create_sql_parts(search, options)
    where = get_where(@@fields, search) || []
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
    
  def create_query(search, options)
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
  
  def create_count_query(search, options)
    select, joins, where = create_sql_parts(search, options)
    
    <<EOSQL
        SELECT count(DISTINCT users.id)
        FROM users
        #{joins.join(' ')}
        #{'WHERE ' + where.join(' AND ') unless where.blank?} 
EOSQL
  end  
  
  def search search, options = {}
    User.find_by_sql(create_query(search.symbolize_keys, options))
  end
  
  def search_ids search, options = {}
    sql = create_query(search.symbolize_keys, options)
    result = ActiveRecord::Base.connection.execute("SELECT id FROM ("+sql+") as id_table;")
    result.collect{ |res| res[0] }
  end
  
  def paginate params, options = {}
    search = params[:search].symbolize_keys
    count = User.count_by_sql(create_count_query(search, options))

    # paging
    page = (params[:page] || 1).to_i
    if (count < (page-1)*50) 
      # reset page, if not enough results
      page = 1
    end

    sql = User.create_query(search, options) + " LIMIT 50 OFFSET "+((page-1)*50).to_s
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
end
