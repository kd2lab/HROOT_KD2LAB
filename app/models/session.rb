class Session < ActiveRecord::Base
  has_event_calendar
  
  belongs_to :experiment
  belongs_to :location
  has_many :participations
  
  validates_presence_of :start_at
  validates_presence_of :end_at
  
  validates_numericality_of :needed, :only_integer => true
  validates_numericality_of :reserve, :only_integer => true
  
  def self.session_times
    (0..23).to_a.product(["00","15","30","45"]).collect{|t| ("%02d:%02d" % t)}
  end
  
  def start_date
    if start_at
      start_at.to_date
    else
      Date.today
    end
  end
  
  def start_time
    if start_at
      start_at.strftime("%H:%M")
    else
      "10:00"
    end
  end
  
  def duration
    begin
      (end_at - start_at).round / 60
    rescue
      90
    end
  end
  
  def full_name
    experiment.name+' ('+start_at.to_date.to_s+', '+start_at.strftime("%H:%M")+"-"+end_at.strftime("%H:%M")+')'
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
end
