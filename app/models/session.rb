class Session < ActiveRecord::Base
  belongs_to :experiment
  belongs_to :location
  has_many :participations
  
  validates_presence_of :start
  validates_presence_of :start_date
  validates_presence_of :start_time
  validates_presence_of :duration
  validates_numericality_of :needed, :only_integer => true
  validates_numericality_of :reserve, :only_integer => true
  
  # splitting of start date in date and time component
  before_validation :set_date
  attr_accessor :start_date
  attr_accessor :start_time
  

  def self.session_times
    (0..23).to_a.product(["00","15","30","45"]).collect{|t| ("%02d:%02d" % t)}
  end
  
  def after_initialize
    @start_date = if self.start then self.start.to_date else "" end
    @start_time = if self.start then self.start.strftime("%H:%M") else "" end
  end
  
  protected
  
  
  def set_date
    begin
      self.start = DateTime.parse(@start_date+" "+@start_time)
    rescue
      self.start = nil
      self.start_date = ""
    end
  end
  
end
