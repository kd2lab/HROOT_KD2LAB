class ParticipantsController < ApplicationController
  before_filter :load_experiment
  
  helper_method :sort_column, :sort_direction
  
  def index
    if params[:search]
      @participants = @experiment.participants
                     .where('(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)',
                       '%'+params[:search]+'%',  '%'+params[:search]+'%',  '%'+params[:search]+'%',
                     )
                     .order("lastname, firstname")
                     .paginate(:per_page => 50, :page => params[:page])  
    else
      @participants = @experiment.participants
                      .order("lastname, firstname")
                      .paginate(:per_page => 50, :page => params[:page])
    end
  end
  
  def manage
    params[:active] = {} unless params[:active]
    
    where = []
    having = []
    
    # search
    unless params[:search].blank?
      where << ActiveRecord::Base.send(:sanitize_sql_array, ['(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)', '%'+params[:search]+'%','%'+params[:search]+'%','%'+params[:search]+'%'])
    end
    # gender
    if params[:active][:f1] == '1'
      where << "users.gender='#{params[:gender]}'"
    end
    
    # noshow
    if params[:active][:f2] == '1'
      having << "noshow_count #{params[:noshow_op]} #{params[:noshow]}"
    end
    
    # register
    if params[:active][:f3] == '1'
      having << "participations_count #{params[:register_op]} #{params[:register]}"
    end
    
    # study
    if params[:active][:f5] == '1' && params[:study]
      s = "users.study_id IN (#{params[:study].join(', ')})"
      
      if params[:study_op] == "Ohne"
        where << "NOT(#{s})"
      else
        where << s
      end
    end
    
    #experiment types
    experiment_typ_subquery = ""
    if params[:active][:f6] == "1"
      # if the user even has selected some experiments
      if params[:experiment_type]
        if params[:exp_typ_op] == "Nur"
          experiment_type_join  = "JOIN participations as tp ON tp.user_id = users.id AND tp.participated = 1 "
          experiment_type_join += "JOIN experiments ON tp.experiment_id = experiments.id AND experiments.experiment_type_id IN (#{params[:experiment_type].join(',')})"
        end
        
        if params[:exp_typ_op] == "Ohne"
          experiment_typ_subquery = ", (SELECT COUNT(participations.id) FROM participations, experiments WHERE user_id = users.id AND participations.participated=1 AND participations.experiment_id=experiments.id AND experiments.experiment_type_id IN (#{params[:experiment_type].join(',')})) AS forbidden_type_count "
          having << "forbidden_type_count = 0"
        end
      end
    end
    
    
   
    #experiments
    if params[:active][:f7] == "1"
      # if the user even has selected some experiments
      if params[:experiment]
        
        # at least one ...
        if params[:exp_op] == "zu einem der"
          experiment_join = "JOIN participations ON participations.user_id = users.id AND participations.experiment_id IN (#{params[:experiment].join(',')})"  
          if params[:exp_op2] == "und teilgenommen haben"
            experiment_join += " AND participations.participated = 1"
          end
        end
        
        # all of them ..
        if params[:exp_op] == "zu allen der"
          experiment_join = ''
          params[:experiment].each do |i|
            single_join = "JOIN participations as p#{i} ON p#{i}.user_id = users.id AND p#{i}.experiment_id = #{i} "
            if params[:exp_op2] == "und teilgenommen haben"
              single_join += " AND p#{i}.participated = 1 "
            end
            experiment_join += single_join  
          end
        end
        
        # none of them...
        if params[:exp_op] == "zu keinem der"
          if params[:exp_op2] == "und teilgenommen haben"
            and_add = " AND participations.participated = 1"
          end
          experiment_subquery = ", (SELECT COUNT(participations.id) FROM participations WHERE user_id = users.id #{and_add} AND participations.experiment_id IN (#{params[:experiment].join(',')})) AS forbidden_count "
          having << "forbidden_count = 0"
        end
        
      end
    end
     
    sql = <<EOSQL
      SELECT 
        DISTINCT users.*, 
          (SELECT COUNT(participations.id) 
          FROM participations, experiments
          WHERE
            participations.experiment_id = experiments.id AND 
            user_id = users.id AND 
            participations.registered = 1 AND
            experiments.finished = 1 AND
            experiments.show_in_stats = 1) AS participations_count,
          (SELECT COUNT(participations.id) 
          FROM participations, experiments
          WHERE
             participations.experiment_id = experiments.id AND 
             user_id = users.id AND 
             participations.registered = 1 AND
             experiments.show_in_stats = 1 AND
             experiments.finished = 1 AND
             participations.showup = 0) AS noshow_count
          #{experiment_subquery}
          #{experiment_typ_subquery}
      FROM users
      #{experiment_join}
      #{experiment_type_join}
      WHERE 
        users.deleted=0 AND
        role='user'
        #{ 'AND' unless where.blank? }
        #{where.join(' AND ')}
      #{ 'HAVING' unless having.blank? }
        #{having.join(' AND ')}
      ORDER BY lastname, firstname
EOSQL
     
    @users = User.find_by_sql(sql)  #.paginate(:per_page => 50, :page => params[:page])  
  end
  
  protected
  
  def load_experiment
    @experiment = Experiment.find_by_id(params[:experiment_id])
    if @experiment
      authorize! :all, @experiment
    else
      redirect_to root_url
    end
  end
  
  private

  def sort_column
    User.column_names.include?(params[:sort]) ? params[:sort] : "lastname"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
