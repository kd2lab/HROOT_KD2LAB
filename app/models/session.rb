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
  
end
