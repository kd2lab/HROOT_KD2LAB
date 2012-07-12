# encoding:utf-8

class User < ActiveRecord::Base
  acts_as_taggable_on :tags
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # for email check on registration
  attr_accessor :email_prefix, :email_suffix
  
  # flag for admin update
  attr_accessor :admin_update

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :secondary_email, :password, :password_confirmation, :remember_me, :firstname, :lastname, 
                  :matrikel, :role, :phone, :gender, :begin_month, :begin_year, :study_id, :deleted, 
                  :email_prefix, :email_suffix, 
                  :country_name, :terms_and_conditions, :lang1, :lang2, :lang3, :profession_id, :degree_id, :birthday,
                  :preference, :experience, :imported, :activated_after_import, :import_token
  
  ROLES = %w[user experimenter admin]
  
  has_many :experimenter_assignments
  has_many :experiments, :through => :experimenter_assignments, :source => :experiment
  has_many :participations
  has_many :participating_experiments, :through => :participations, :source => :experiment
  has_many :session_participations
  has_many :sessions, :through => :session_participations
  has_many :login_codes
  has_settings

  belongs_to :study
  belongs_to :profession
  belongs_to :degree
  
  
  def is_not_admin_update?
    !admin_update
  end
  
  with_options :if => :is_not_admin_update? do |import_user|
    import_user.validates_presence_of :birthday, :on => :create
  end
  
  validates_presence_of :firstname, :lastname, :matrikel, :gender
  
  validates_uniqueness_of :calendar_key
  validates_acceptance_of :terms_and_conditions
  validates :secondary_email, :email => true, :allow_blank => true
    
  # http://www.zorched.net/2009/05/08/password-strength-validation-with-regular-expressions/                                        
  validates_format_of :password, :with => /^.*(?=.{8,})(?=.*[a-zA-Z])(?=.*[\W_])(?=.*[\d]).*$/, :if => :password_present?
  def password_present?
    !password.nil?
  end
  
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
  
  def has_right?(experiment, right)
    admin? || experiment.experimenter_assignments.where(:user_id => id).where(["rights LIKE ?", '%'+right+'%']).count > 0
  end
  
  def language_ids
    ([lang1] + [lang2] + [lang3]).compact.uniq
  end
  
  def languages
    langs = Language.find(language_ids).map &:name
  end
  
  def main_email
    if secondary_email_confirmed_at
      secondary_email
    elsif confirmed_at
      email
    else
      ""
    end
  end
  
  def available_sessions
    sql = <<EOSQL
SELECT 
 sessions.*
FROM 
  sessions, experiments, participations
WHERE
  experiments.registration_active=1 AND              
  sessions.experiment_id = experiments.id AND
  sessions.id = sessions.reference_session_id AND
  participations.user_id = #{self.id} AND
  participations.experiment_id = experiments.id AND
  start_at > NOW() AND
  
  (SELECT COUNT(id) FROM session_participations WHERE session_participations.session_id = sessions.id) < sessions.needed+sessions.reserve AND
  
  (SELECT COUNT(*) 
   FROM session_participations, sessions s2 
   WHERE session_participations.session_id = s2.id AND session_participations.user_id=#{self.id} AND s2.experiment_id = experiments.id
  ) = 0 AND
  
  (SELECT COUNT(*) 
   FROM session_participations sp, sessions s3 
   WHERE
     sp.session_id = s3.id AND sp.user_id=#{self.id} AND 
     s3.end_at > sessions.start_at AND s3.start_at < sessions.end_at
  ) = 0
ORDER BY sessions.start_at ASC
 
EOSQL

    Session.find_by_sql(sql)
  end
  
  # load users and aggregate participation data
  def self.create_filter_sql params, options, counting = false
    where = []
    
    filter = params[:filter] || {}
    options = options || {}
    
    sort_column = options[:sort_column] || 'lastname'
    sort_direction = options[:sort_direction] || 'ASC'
    experiment = options[:experiment]
    
    # search
    unless filter[:search].blank?
      where << ActiveRecord::Base.send(:sanitize_sql_array, ['(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)', '%'+filter[:search]+'%','%'+filter[:search]+'%','%'+filter[:search]+'%'])
    end
    
    # also show deleted users?
    unless options[:include_deleted_users]
      where << "users.deleted=0"
    end
    
    # gender
    if ['f', 'm', '?'].include?(filter[:gender])
      where << "users.gender='#{filter[:gender]}'"
    end
        
    # preference
    if [1,2].include?(filter[:preference].to_i)
      where << "(users.preference=0 OR users.preference=#{filter[:preference].to_i})"
    end
    
    # role
    if User.roles.values.include?(filter[:role])
      where << "users.role='#{filter[:role]}'"
    end
    
    # noshow
    if ["<=", ">"].include?(filter[:noshow_op])
      where << "noshow_count #{filter[:noshow_op]} #{filter[:noshow].to_i}"
    end
    
    # successful participations
    if ["<=", ">"].include?(filter[:participated_op])
      where << "participations_count #{filter[:participated_op]} #{filter[:participated].to_i}"
    end
    
    # activation after import
    if filter.has_key?(:activated_after_import)
      if filter[:activated_after_import]
        where << 'users.activated_after_import=1'
      else
        where << 'users.activated_after_import=0'
      end
    end
        
    #studienbeginn
    if (1..12).include?(filter[:begin_von_month].to_i) && filter[:begin_von_year].to_i > 1990
      begin_select = "str_to_date(CONCAT_WS('-', COALESCE(begin_year, 1990), COALESCE(begin_month,1), '1'), '%Y-%m-%d') as begin_date, "
      where << "((begin_month >= #{filter[:begin_von_month].to_i} AND begin_year=#{filter[:begin_von_year].to_i}) OR (begin_year>#{filter[:begin_von_year].to_i}))"
    end

    if (1..12).include?(filter[:begin_bis_month].to_i) && filter[:begin_bis_year].to_i > 1990
      begin_select = "str_to_date(CONCAT_WS('-', COALESCE(begin_year, 1990), COALESCE(begin_month,1), '1'), '%Y-%m-%d') as begin_date, "
      where << "((begin_month <= #{filter[:begin_bis_month].to_i} AND begin_year=#{filter[:begin_bis_year].to_i}) OR (begin_year<#{filter[:begin_bis_year].to_i}))"
    end
  
    # birthday
    if (1..12).include?(filter[:birthday_von_month].to_i) && filter[:birthday_von_year].to_i >= 1900 && filter[:birthday_von_year].to_i <= Time.now.year
      where << "birthday >= '#{filter[:birthday_von_year].to_i}-#{filter[:birthday_von_month].to_i}-01'"
    end

    if (1..12).include?(filter[:birthday_bis_month].to_i) && filter[:birthday_bis_year].to_i >= 1900 && filter[:birthday_bis_year].to_i <= Time.now.year
      where << "birthday <= '#{filter[:birthday_bis_year].to_i}-#{filter[:birthday_bis_month].to_i}-31'"
    end
    
    # external experience
    if filter[:experience]
      where << "experience = #{filter[:experience].to_i}"
    end
    
    # study 
    if filter[:study]
      s = "users.study_id IN (#{filter[:study].map(&:to_i).join(', ')})"
      
      if filter[:study_op] == "Ohne"
        where << "(NOT(#{s}) OR users.study_id IS NULL)"
      else
        where << s
      end
    end

    # degree
    if filter[:degree]
      s = "users.degree_id IN (#{filter[:degree].map(&:to_i).join(', ')})"
      
      if filter[:degree_op] == "Ohne"
        where << "(NOT(#{s}) OR users.degree_id IS NULL)"
      else
        where << s
      end
    end
    
    # languages
    if filter[:language]
      where << "(users.lang1 IN (#{filter[:language].map(&:to_i).join(', ')}) OR "+
               " users.lang2 IN (#{filter[:language].map(&:to_i).join(', ')}) OR "+
               " users.lang3 IN (#{filter[:language].map(&:to_i).join(', ')})) "
    end
    
    #experiment tags
    # todo guard against sql injection
    
    filter[:exp_tag_count].to_i.times do |i|
      if filter["exp_tag#{i}"].length > 0
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
             tags.name LIKE "#{filter["exp_tag#{i}"]}")
EOSQL
        
        
        if filter['exp_tag_op1'][i] == "Mindestens"
          experiment_tag_subquery += " >= #{filter["exp_tag_op2"][i].to_i}"
        elsif filter['exp_tag_op1'][i] == "Höchstens"
          experiment_tag_subquery += " <= #{filter["exp_tag_op2"][i].to_i}"
        end
        where << experiment_tag_subquery
      end  
    end
    
    #experiments
    # if the user even has selected some experiments
    if filter[:experiment]
      ids = filter[:experiment].map(&:to_i).join(',')
    
      # at least one ...
      case filter[:exp_op]
      when "die zu einem der folgenden Experimente zugeordnet sind"
        experiment_join = "JOIN participations ON participations.user_id = users.id AND participations.experiment_id IN (#{ids})"  
      when "die zu allen der folgenden Experimente zugeordnet sind"
        experiment_join = filter[:experiment].map(&:to_i).collect{|id| "JOIN participations as p#{id} ON p#{id}.user_id = users.id AND p#{id}.experiment_id = #{id}"}.join(' ')
      when "die zu keinem der folgenden Experimente zugeordnet sind"
        where << "(SELECT COUNT(participations.id) FROM participations WHERE user_id = users.id AND participations.experiment_id IN (#{ids})) = 0"
      when "die an mindestens einer Session eines der folgenden Experimente teilgenommen haben"
        experiment_join = "JOIN sessions s ON s.experiment_id IN (#{ids}) JOIN session_participations sp ON sp.participated=1 AND s.id = sp.session_id AND sp.user_id = users.id "  
      when "die an mindestens einer Session von jedem der folgenden Experimente teilgenommen haben"
        experiment_join = filter[:experiment].map(&:to_i).collect do |id| 
          "JOIN sessions s#{id} ON s#{id}.experiment_id=#{id} JOIN session_participations p#{id} ON p#{id}.user_id = users.id AND p#{id}.session_id = s#{id}.id "
        end.join(' ')
      when "die an keiner Session der folgenden Experimente teilgenommen haben"
        where << "(SELECT COUNT(sp.id) FROM sessions s, session_participations sp WHERE sp.participated = 1 AND sp.user_id = users.id AND s.id = sp.session_id AND s.experiment_id IN (#{ids})) = 0"
      end
    end
          
    # include / exclude participants in experiment
    session_select = ''
    session_participation_join = ''
    if experiment
      participation_join = "LEFT JOIN participations p ON p.user_id = users.id AND p.experiment_id = #{experiment.id} "
      
      # exclude members
      if options[:exclude_experiment_participants]
        where << "p.id IS NULL"
      end

      # only members
      if options[:exclude_non_participants]
        where << "p.id IS NOT NULL"
        
        # limit to users of a certain session
        if filter[:session]
          # load session_participation and join reference sessions
          session_participation_join = "JOIN (sessions sj JOIN session_participations sps ON sj.id = sps.session_id AND sj.id = #{filter[:session].to_i}) ON sj.experiment_id = #{experiment.id} AND sps.user_id = users.id "         
          session_select = "sps.reminded_at, sj.start_at as session_start_at, sj.id as session_id, p.invited_at, sps.showup as session_showup, sps.noshow as session_noshow, sps.participated as session_participated, "
        else
          # load session_participation and join reference sessions
          session_participation_join = "LEFT JOIN (sessions sj JOIN session_participations sps ON sj.id = sps.session_id) ON sj.experiment_id = #{experiment.id} AND sj.id = sj.reference_session_id AND sps.user_id = users.id "         
          session_select = "sps.reminded_at, sj.start_at as session_start_at, sj.id as session_id, p.invited_at, sps.showup as session_showup, sps.noshow as session_noshow, sps.participated as session_participated, "
        end

        # only select users with a successful participation
        # this filter only makes sense, when we select participants of an experiment
        if filter[:participation]
          where << "sps.participated = 1" if filter[:participation] == '1'
          where << "sps.session_id > 0" if filter[:participation] == '2'
          where << "(sps.session_id IS NULL)" if filter[:participation] == '3'
        end  
      end
    end  
      
    # counting or selecting?
    if counting
      user_select = "count(DISTINCT users.id),"     
    else
      user_select = "DISTINCT users.*,"
    end
          
    sql = <<EOSQL
      SELECT 
          #{user_select}
          #{session_select} 
          #{begin_select}
          
          (SELECT studies.name
              FROM studies
              WHERE studies.id = users.study_id
          ) as study_name
      FROM users
      #{experiment_join}
      #{participation_join}
      #{session_participation_join}
      #{'WHERE' unless where.blank?} 
        #{where.join(' AND ')}
      ORDER BY #{sort_column + ' ' + sort_direction} 
EOSQL
  
    return sql
  end
  
  def self.update_noshow_calculation(ids = nil)
    sql = <<EOSQL
UPDATE users
SET
  participations_count = COALESCE(
            (SELECT
              count(sessions.id)
            FROM sessions, session_participations, experiments
            WHERE
              sessions.id = sessions.reference_session_id AND
              session_participations.session_id = sessions.id AND
              session_participations.user_id = users.id AND
              experiments.id = sessions.experiment_id AND
              (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = sessions.id) =
              (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  s.session_id = s2.id AND s.user_id = users.id AND s2.reference_session_id = sessions.id AND s.showup = 1) 
              AND
              (SELECT count(s.id)  FROM sessions s WHERE s.reference_session_id = sessions.id) > 0
              AND
              experiments.show_in_stats = 1
            ), 
            0
          ),
          
  noshow_count=COALESCE(
            (SELECT
              count(sessions.id)
            FROM sessions, session_participations, experiments
            WHERE
              sessions.id = sessions.reference_session_id AND
              session_participations.session_id = sessions.id AND
              session_participations.user_id = users.id AND
              experiments.id = sessions.experiment_id AND
              experiments.show_in_stats = 1 AND
              (SELECT count(s.id)  FROM session_participations s, sessions s2 WHERE  s.session_id = s2.id AND s.user_id=users.id AND s2.reference_session_id = sessions.id AND s.noshow = 1) >0
            ),
            0
          )
EOSQL

    sql += " WHERE users.id IN (#{ids.map(&:to_i).join(',')}) " if ids

    result = ActiveRecord::Base.connection.execute(sql)
  
  end
    
  def self.paginate params, options = nil
    page = (params[:page] || 1).to_i
    
    if params[:filter] && ( params[:filter].keys.count > 0 || (options && options[:experiment]) || ! params[:filter][:search].blank?)
      count = User.count_by_sql(User.create_filter_sql(params, options, true))
    elsif options && options[:include_deleted_users]
      count = User.count
    else  
      count = User.where('deleted=0').count
    end
  
    # reset page, if not enough results
    if (count < (page-1)*50) 
      page = 1
    end
    
    sql = User.create_filter_sql(params, options)+ " LIMIT 50 OFFSET "+((page-1)*50).to_s
    objects = User.find_by_sql(sql)
    
    return WillPaginate::Collection.create(page,50) do |pager|    
      pager.replace(objects)
      pager.total_entries = count
    end
    
  end
  
  def User.load params, options = nil
    User.find_by_sql(User.create_filter_sql(params, options))    
  end
  
  def User.load_ids params, options = nil
    sql = User.create_filter_sql(params, options)
    result = ActiveRecord::Base.connection.execute("SELECT id FROM ("+sql+") as id_table;")
    result.collect{ |res| res[0] }
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
  
  def self.check_email prefix, suffix
    if Settings.mail_restrictions
      Settings.mail_restrictions.each do |r|
        return true if r['suffix'] == suffix && (r['prefix'].blank? || prefix.include?(r['prefix']))
      end
      return false
    end    
    return true
  end
  
  def is_missing_data?
    study_id.nil? || birthday.nil? || degree_id.nil? || country_name.nil? || preference.nil? || experience.nil? || (lang1.nil? && lang2.nil? && lang3.nil?) || begin_year.nil? || begin_month.nil?
  end
  
end
