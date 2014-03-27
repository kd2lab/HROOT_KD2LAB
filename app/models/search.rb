


class Search
  @@fields = {}

  # adds a search field to the list
  def self.add(field)
    @@fields[field.name] = field
  end  
  
  # default search fields
  add FulltextSearchField.new(:fulltext)
  add SelectionSearchField.new(:role, :db_values => User.roles, :translate => true, :translation_prefix => "search.selections")
  add ParticipationSearchField.new(:participation, :db_values => [1,2,3,4], :translate => true, :translation_prefix => "search.selections")
  add DeletedSearchField.new(:deleted, :db_values => ["hide", "show"], :translate => true, :translation_prefix => "search.selections")
  add IntegerSearchField.new(:noshow_count, :range => 0..(User.maximum(:noshow_count) || 10))
  add IntegerSearchField.new(:participations_count, :range => 0..(User.maximum(:participations_count) || 10))
  add TagsSearchField.new(:tags)
  add ExperimentsSearchField.new(:experiments)
  
  # add search field for all custom fields
  CUSTOM_FIELDS.fields.each do |field|
    add field.search_field
  end  
  
  # returns the partial for a specific search field
  def self.partial_for(name)
    if @@fields[name]
      @@fields[name].partial
    else
      "shared/search/undefined"
    end
  end

  # returns the local variables to pass to partial rendering
  def self.options_for(name)
    if @@fields[name]
      @@fields[name].options.merge({:name => name})
    else
      {:name => 'Undefined'}
    end
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

    # remove blanks or nils
    result.reject!(&:blank?)
    result
  end  
    
  # creates the where, select and join parts of the full query
  def self.create_sql_parts(search, options)
    where = where_conditions(search)
    joins = []
    select = ['DISTINCT users.*']
    experiment = options[:experiment]
    group = []

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
          select << "sps.reminded_at,
                   sj.start_at as session_start_at,
                   sj.id as session_id, 
                   p.invited_at,
                   p.added_by_public_key, 
                   sps.showup as session_showup, 
                   sps.noshow as session_noshow, 
                   sps.participated as session_participated,
                   sps.seat_nr as seat_nr,
                   sps.payment as payment"
        else
          # or load session_participation and join sessions
          joins << "LEFT JOIN (sessions sj JOIN session_participations sps ON sj.id = sps.session_id) ON sj.experiment_id = #{experiment.id} AND sps.user_id = users.id "
          select << "GROUP_CONCAT(sj.start_at SEPARATOR ',') as session_start_at"
          group << "users.id"
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
    
    return select, joins, where, group
  end
    
  # assembles the full query  
  def self.create_query(search, options)
    select, joins, where, group = create_sql_parts(search, options)
    
    sort_column = options[:sort_column] || 'lastname'
    sort_direction = options[:sort_direction] || 'ASC'
    
    
    
    
    <<EOSQL
        SELECT #{select.join(',')}
        FROM users
        #{joins.join(' ')}
        #{('WHERE ' + where.join(' AND ')) unless where.blank?} 
        #{('GROUP BY ' + group.join(' AND ')) unless group.blank?} 
        ORDER BY #{sort_column + ' ' + sort_direction}   
EOSQL
  end
  
  # assembles a full count query
  def self.create_count_query(search, options)
    select, joins, where, group = create_sql_parts(search, options)
    
    <<EOSQL
        SELECT count(DISTINCT users.id)
        FROM users
        #{joins.join(' ')}
        #{('WHERE ' + where.join(' AND ')) unless where.blank?} 
        #{('GROUP BY ' + group.join(' AND ')) unless group.blank?} 
EOSQL
  end  
  
  # finds  a full list of user objects
  def self.search search, options = {}
    User.find_by_sql(create_query(search.symbolize_keys, options))
  end
  
  # finds a full list of user ids
  def self.search_ids search, options = {}
    sql = create_query(search.symbolize_keys, options)
    result = ActiveRecord::Base.connection.execute("SELECT id FROM ("+sql+") as id_table;")
    result.collect{ |res| res[0] }
  end
  
  # finds a list of users based on the pagination settings
  def self.paginate params, options = {}
    search = params[:search].symbolize_keys
    count = User.count_by_sql(create_count_query(search, options))

    # paging    
    page = (params[:page].to_i || 1).to_i
    page = 1 if page < 1

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

  end    
    
end