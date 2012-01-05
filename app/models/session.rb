#encoding: utf-8

class Session < ActiveRecord::Base
  has_event_calendar
  
  belongs_to :experiment
  belongs_to :location
  has_many :participations
  has_many :session_participations
  
  validates_presence_of :start_at
  validates_presence_of :end_at
  
  validates_numericality_of :needed, :only_integer => true
  validates_numericality_of :reserve, :only_integer => true
  
  scope :in_the_future, lambda { 
    where("start_at > NOW()")
  }
  
  scope :main_sessions, lambda { 
    where("sessions.reference_session_id = sessions.id")
  }
  
  after_create :set_defaults
  def set_defaults
    unless reference_session_id
      self.reference_session_id = self.id
      self.save
    end
  end
  
  def self.session_times
    (0..23).to_a.product(["00","15","30","45"]).collect{|t| ("%02d:%02d" % t)}
  end
  
  def start_date
    if start_at
      start_at.to_date.to_s + " " + start_at.strftime("%H:%M")
    else
      Time.now.strftime("%d.%m.%Y %H:%M")
    end
  end
  
  def duration
    begin
      (end_at - start_at).round / 60
    rescue
      90
    end
  end
  
  def self.move_members(members, experiment, target = nil)
    members.each do |id|
      u = User.find(id)
      if u
        SessionParticipation.where(:user_id => u.id, :session_id => experiment.sessions).delete_all
        p = Participation.find_by_user_id_and_experiment_id(u, experiment)
        p.session_id = target ? target.id : nil
        p.save
      end
    end
  end
    
  def full_name
    experiment.name+' ('+self.time_str+')'
  end
  
  def time_str
    start_at.strftime("%d.%m.%Y %H:%M")+" - "+end_at.strftime("%H:%M")
  end
  
  def mail_string
    "todo: session repräsentation"
  end
    
  def following_sessions
    Session.where(["experiment_id = ? AND reference_session_id = ? AND id <> reference_session_id", self.experiment_id, self.id]).order('start_at').all
  end
  
  def reference_session
    Session.find_by_id reference_session_id
  end
  
  def alternative_sessions
    Session.main_sessions.where(["sessions.experiment_id = ?", experiment_id])
      .where(["sessions.id <> ?", reference_session_id])
      .order(:start_at)
  end
  
  def self.load(experiment_id)
    sql = <<EOSQL
      SELECT 
        sessions.*,
        (SELECT count(participations.id) FROM participations WHERE participations.session_id = sessions.id) as participations_count,
        (SELECT count(session_participations.id) FROM session_participations WHERE session_participations.session_id = sessions.id) as session_participations_count


      FROM sessions
      WHERE
        sessions.experiment_id = # AND
        sessions.reference_session_id = sessions.id
      ORDER BY start_at;
EOSQL

  end
  
  def self.find_overlapping_sessions(year, month)
    sql = <<EOSQL
      SELECT DISTINCT s.*, 
      ( SELECT GROUP_CONCAT(s2.id) 
        FROM sessions s2 
        WHERE s2.end_at >= s.start_at 
        AND s2.start_at <= s.end_at 
        AND s.id < s2.id
        AND s.location_id = s2.location_id)
      AS overlap_ids
      FROM sessions s
      WHERE s.end_at IS NOT NULL  
      AND MONTH(s.start_at) = #{month.to_i} AND YEAR(s.start_at) = #{year.to_i}
      HAVING overlap_ids IS NOT NULL;
EOSQL
    Session.find_by_sql(sql)
  end
  
  def space_left
    needed + reserve - participations.count
  end
  
  def css_class
    surplus = participations.count - needed

    if surplus < 0
      "participants-red"
    elsif surplus < reserve
      "participants-yellow"
    else
      "participants-green"
    end
  end
end
