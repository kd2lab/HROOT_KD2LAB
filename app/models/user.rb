# encoding:utf-8

class User < ActiveRecord::Base
  acts_as_taggable_on :tags
  has_many :experimenter_assignments
  has_many :experiments, :through => :experimenter_assignments, :source => :experiment
  has_many :participations
  has_many :participating_experiments, :through => :participations, :source => :experiment
  has_many :session_participations
  has_many :sessions, :through => :session_participations
  has_many :login_codes
  has_settings
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :timeoutable

  
  # Setup accessible (or protected) attributes for your model - main part
  attr_accessible :email, :secondary_email, :password, :password_confirmation, :remember_me, :firstname, :lastname, :role, :terms_and_conditions, :deleted, :comment
  
  # validations
  validates_presence_of :firstname, :lastname
  validates_uniqueness_of :calendar_key
  validates_acceptance_of :terms_and_conditions
  validates :secondary_email, :email => true, :allow_blank => true
  # http://www.zorched.net/2009/05/08/password-strength-validation-with-regular-expressions/                                        
  validates_format_of :password, :with => /^.*(?=.{8,})(?=.*[a-zA-Z])(?=.*[\W_])(?=.*[\d]).*$/, :if => :password_present?
  
  # validate email on signup
  validates_format_of :email, :with => Rails.configuration.email_restriction[:regex], :on => :create, :if => :is_not_admin_update? if Rails.configuration.respond_to?(:email_restriction)

  # setup custom datafields, see config/initializers/custom_fields.rb  
  CUSTOM_FIELDS.setup_model(self)
  
  # flag for admin update
  attr_accessor :admin_update
  def is_not_admin_update?
    !admin_update
  end
  
  def self.roles
    %w[user experimenter admin]
  end
  
  def self.roles_for_select
    User.roles.map{|r| [I18n.t("roles.#{r}"), r]}
  end
  
  def rolename
    I18n.t("roles.#{role}")
  end
  

  #with_options :if => :is_not_admin_update? do |import_user|
  #  import_user.validates_presence_of :birthday, :on => :create
  #  import_user.validates_presence_of :matrikel
  #end
      
  
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
    # first find all sessions a user could potentially register to
    # criteria:
    # - sessions of experiments with open registrations
    # - user must be invited
    # - session must not be full
    # - user must not have another session at the same time
    # - user must not have chosen another session from the same experiment
    
    sql = <<EOSQL
SELECT 
 sessions.*
FROM 
  sessions, experiments, participations
WHERE
  experiments.registration_active=1 AND              
  sessions.experiment_id = experiments.id AND
  participations.user_id = #{self.id} AND
  participations.experiment_id = experiments.id AND
  start_at > NOW() AND
  
  -- only select sessions, which still have open seats
  (SELECT COUNT(id) FROM session_participations WHERE session_participations.session_id = sessions.id) < sessions.needed+sessions.reserve AND
  
  -- only select sessions where user is not part in another session of the same experiment
  (SELECT COUNT(*) 
   FROM session_participations, sessions s2 
   WHERE session_participations.session_id = s2.id AND session_participations.user_id=#{self.id} AND s2.experiment_id = experiments.id
  ) = 0 AND
  
  -- only select sessions with no time overlap to already chosen sessions
  (SELECT COUNT(*) 
   FROM session_participations sp, sessions s3 
   WHERE
     sp.session_id = s3.id AND sp.user_id=#{self.id} AND 
     s3.end_at > sessions.start_at AND s3.start_at < sessions.end_at
  ) = 0

ORDER BY sessions.start_at ASC
 
EOSQL

    sessions = Session.find_by_sql(sql)

    # now load all experiment ids where the user as participated
    experiment_ids = session_participations.where("noshow != 1").includes(:session).map{|p| p.session.experiment_id}
    
    # for each session calculate the ids of experiments to exclude based on exclude_experiments and exclude_tags
    sessions_after_exclusion = sessions.select do |session|
      # only keep sessions where the list of the excluded experiment ids intersected with the 
      # ids of experiments the user participated in is length zero
      (session.experiment.excluded_ids & experiment_ids).length == 0
    end  

    sessions_after_exclusion

    # split up - ungrouped sessions and grouped sessions
    ungrouped_sessions, grouped_sessions = sessions_after_exclusion.partition do |s| s.session_group_id.nil? end


    # post processing on grouped sessions - only keep groups, where all sessions in the group are eligable for enrollment

    # count number of sessions per group result will be a hash like {nil=>9, 10=>2, 100=>3}  (session_group_id => number of sessions)
    # but first, only do that for relevant group ids
    group_ids = grouped_sessions.collect do |s| s.session_group_id end
    group_counts = Session.where(:session_group_id => group_ids).group(:session_group_id).count

    # filter out groups where ALL sesssions are in sessions_after_exclusion
    final_grouped_sessions = grouped_sessions.group_by{|s| s.session_group_id}.select do |group_id, sessions|
      !group_id.nil? && sessions.size == group_counts[group_id]
    end

    # now we know the ids of the groups available to the user, we now load the SessionGroups together with their sessions
    session_groups = SessionGroup.where(:id => final_grouped_sessions.keys.uniq).includes(:sessions).order('sessions.start_at')


    return ungrouped_sessions, session_groups
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
