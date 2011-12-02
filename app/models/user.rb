# encoding:utf-8

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # for email check on registration
  attr_accessor :email_prefix, :email_suffix

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :secondary_email, :password, :password_confirmation, :remember_me, :firstname, :lastname, :matrikel, :role, :phone, :gender, :begin_month, :begin_year, :study_id, :deleted, :email_prefix, :email_suffix
  
  ROLES = %w[user experimenter admin]
  
  has_many :experimenter_assignments
  has_many :experiments, :through => :experimenter_assignments, :source => :experiment
  has_many :participations
  has_many :participating_experiments, :through => :participations, :source => :experiment
  has_many :session_participations
  has_many :login_codes
  has_settings

  belongs_to :study
  
  validates_presence_of :firstname, :lastname, :matrikel
  validates_uniqueness_of :calendar_key
  validates :secondary_email, :email => true, :allow_blank => true
  
  after_create :set_defaults
  
  def set_defaults
    self.role = 'user'
    self.calendar_key = SecureRandom.hex(16)
    self.save
  end
  
  # for devise: only allow non-deleted users
  def self.find_for_authentication(conditions)
    super(conditions.merge(:deleted => false))
  end
  
  def admin?
    role == "admin"
  end
  
  def user?
    role == 'user'
  end
  
  def experimenter?
    role == 'experimenter'
  end
  
  def available_sessions
    # find all ids of experiments where the user is assigned and registration is open
    # and the user has not defined his participation status
    ids = participating_experiments.where(:registration_active => true, 'participations.session_id' => nil).map(&:id)
      
    #find all future sessions, which still have space and are open
    Session.in_the_future
      .where(:experiment_id => ids)
      .where("sessions.reference_session_id = sessions.id")
      .order('start_at')
      .select{ |s| s.space_left > 0}
  end
  
  # load users and aggregate participation data
  def self.load params, sort_column='lastname', sort_direction='ASC', experiment = nil, options = nil
    where = []
    having = []
    
    #require :active param
    params[:active] = {} unless params[:active]
    params[:exp_typ_op1] ||= []
    params[:exp_typ_op2] ||= []
    params[:exp_typ] ||= []
    
    # search
    unless params[:search].blank?
      where << ActiveRecord::Base.send(:sanitize_sql_array, ['(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)', '%'+params[:search]+'%','%'+params[:search]+'%','%'+params[:search]+'%'])
    end
    
    # also show deleted users?
    unless options && options[:include_deleted_users]
      where << "users.deleted=0"
    end
    
    # gender
    if params[:active][:fgender] == '1' && ['f', 'm'].include?(params[:gender])
      where << "users.gender='#{params[:gender]}'"
    end
    
    # role
    if params[:active][:frole] == '1' && User.roles.values.include?(params[:role])
      where << "users.role='#{params[:role]}'"
    end
    
    # noshow
    if params[:active][:fnoshow] == '1' && ["<=", ">"].include?(params[:noshow_op])
      having << "noshow_count #{params[:noshow_op]} #{params[:noshow].to_i}"
    end
    
    # successful participations
    if params[:active][:fparticipated] == '1'&& ["<=", ">"].include?(params[:participated_op])
      having << "participations_count #{params[:participated_op]} #{params[:participated].to_i}"
    end
    
    #studienbeginn
    if params[:active][:fbegin] == '1'
      if (1..12).include?(params[:begin_von_month].to_i) && params[:begin_von_year].to_i > 1990
        where << "((begin_month >= #{params[:begin_von_month].to_i} AND begin_year=#{params[:begin_von_year].to_i}) OR (begin_year>#{params[:begin_von_year].to_i}))"
      end

      if (1..12).include?(params[:begin_bis_month].to_i) && params[:begin_bis_year].to_i > 1990
        where << "((begin_month <= #{params[:begin_bis_month].to_i} AND begin_year=#{params[:begin_bis_year].to_i}) OR (begin_year<#{params[:begin_bis_year].to_i}))"
      end
    end
    
    # study 
    if params[:active][:fstudy] == '1' && params[:study]
      s = "users.study_id IN (#{params[:study].map(&:to_i).join(', ')})"
      
      if params[:study_op] == "Ohne"
        where << "(NOT(#{s}) OR users.study_id IS NULL)"
      else
        where << s
      end
    end
    
    #experiment types
    experiment_typ_subquery = ""
    if params[:active][:fexperimenttype] == '1'
      params[:exp_typ_count].to_i.times do |i|
        if params["exp_typ#{i}"].to_i > 0
          experiment_typ_subquery += t =  "(SELECT COUNT(participations.id) FROM participations, experiments WHERE user_id = users.id AND 
          (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = participations.session_id) =
          (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  
             s.user_id = users.id AND
             s.session_id = s2.id AND 
             s2.reference_session_id = participations.session_id AND s.participated = 1)
          AND (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = participations.session_id) > 0
          AND participations.experiment_id=experiments.id AND experiments.experiment_type_id = #{params["exp_typ#{i}"].to_i}) AS exp_type_count#{i}, \n"
               
          if params['exp_typ_op1'][i] == "Mindestens"
            having << "exp_type_count#{i} >= #{params["exp_typ_op2"][i].to_i}"
          elsif params['exp_typ_op1'][i] == "Höchstens"
            having << "exp_type_count#{i} <= #{params["exp_typ_op2"][i].to_i}"
          end
  
        end    
      end
    end
    
    #experiments
    if params[:active][:fexperiment] == '1'
      # if the user even has selected some experiments
      if params[:experiment]
        # at least one ...
        if params[:exp_op] == "zu einem der"
          experiment_join = "JOIN participations ON participations.user_id = users.id AND participations.experiment_id IN (#{params[:experiment].map(&:to_i).join(',')})"  
          if params[:exp_op2] == "teilgenommen haben"
            experiment_join += " AND (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = participations.session_id) =
            (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  
               s.user_id = users.id AND
               s.session_id = s2.id AND 
               s2.reference_session_id = participations.session_id AND s.participated = 1) AND (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = participations.session_id) > 0"
          end
        end
        
        # all of them ..
        if params[:exp_op] == "zu allen der"
          experiment_join = ''
          params[:experiment].map(&:to_i).each do |i|
            single_join = "JOIN participations as p#{i} ON p#{i}.user_id = users.id AND p#{i}.experiment_id = #{i} "
            if params[:exp_op2] == "teilgenommen haben"
              single_join += " AND (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = p#{i}.session_id) =
              (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  
                 s.user_id = users.id AND
                 s.session_id = s2.id AND 
                 s2.reference_session_id = p#{i}.session_id AND s.participated = 1)
              AND 
              (SELECT count(s.id) FROM sessions s WHERE s.reference_session_id = p#{i}.session_id) > 0 "              
            end
            experiment_join += single_join  
          end
        end
        
        # none of them...
        if params[:exp_op] == "zu keinem der"
          if params[:exp_op2] == "teilgenommen haben"
            and_add = " AND (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = participations.session_id) =
            (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  
               s.user_id = users.id AND
               s.session_id = s2.id AND 
               s2.reference_session_id = participations.session_id AND s.participated = 1) AND (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = participations.session_id) > 0"
          end
          experiment_subquery = "(SELECT COUNT(participations.id) FROM participations WHERE user_id = users.id #{and_add} AND participations.experiment_id IN (#{params[:experiment].map(&:to_i).join(',')})) AS forbidden_count, "
          having << "forbidden_count = 0"
        end
        
      end
    end
    
    # include / exclude participants in experiment
    if experiment 
      participation_subquery = "(SELECT participations.id FROM participations"+
          " WHERE participations.user_id = users.id AND participations.experiment_id = #{experiment.id}) as part_id,"
      
      # exclude members
      if options && options[:exclude_experiment_participants]
        having << "part_id IS NULL"
      end

      # only members
      if options && options[:exclude_non_participants]
        having << "part_id IS NOT NULL"
        
        # in this case, also load invitation date
        invitation_subquery = "(SELECT participations.invited_at FROM participations"+
            " WHERE participations.user_id = users.id AND participations.experiment_id = #{experiment.id}) as invited_at,"
      end
    end  
      
          
    sql = <<EOSQL
      SELECT 
        DISTINCT users.*, 
          COALESCE(
            (SELECT
              count(sessions.id)
            FROM sessions, participations, experiments
            WHERE
              sessions.id = sessions.reference_session_id AND
              participations.session_id = sessions.id AND
              participations.user_id = users.id AND
              experiments.id = sessions.experiment_id AND
              (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = sessions.id) =
              (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  s.session_id = s2.id AND s.user_id = users.id AND s2.reference_session_id = sessions.id AND s.participated = 1) 
              AND
              (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = sessions.id) > 0
              AND
              experiments.show_in_stats = 1
            ), 
            0
          ) AS participations_count,
          COALESCE(
            (SELECT
              count(sessions.id)
            FROM sessions, participations, experiments
            WHERE
              sessions.id = sessions.reference_session_id AND
              participations.session_id = sessions.id AND
              participations.user_id = users.id AND
              experiments.id = sessions.experiment_id AND
              experiments.show_in_stats = 1 AND
              (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  s.session_id = s2.id AND s.user_id=users.id AND s2.reference_session_id = sessions.id AND s.noshow = 1) >0
            ),
            0
          ) AS noshow_count,
          (SELECT studies.name
              FROM studies
              WHERE studies.id = users.study_id
          ) as study_name,
          #{participation_subquery}
          #{experiment_subquery}
          #{experiment_typ_subquery}
          #{invitation_subquery}
          str_to_date(CONCAT_WS('-', COALESCE(begin_year, 1990), COALESCE(begin_month,1), '1'), '%Y-%m-%d') as begin_date
      FROM users
      #{experiment_join}
      #{'WHERE' unless where.blank?} 
        #{where.join(' AND ')}
      #{'HAVING' unless having.blank?} 
        #{having.join(' AND ')}
      ORDER BY #{sort_column + ' ' + sort_direction}
EOSQL
    
    User.find_by_sql(sql)
  end
  
  def self.roles
    {"Poolmitglied (P)" => "user", "Experimentator (E)" => "experimenter", "Administrator (A)" => "admin"}
  end
  
  def begin_date
    "#{"%02d" % begin_month}/#{begin_year} " unless begin_month.blank? || begin_year.blank?
  end
  
  def create_code
    begin 
      l = LoginCode.create(:user => self, :code => rand(36**10).to_s(36))
    end while !l.valid?
    
    return l.code
  end  
  
   
end
