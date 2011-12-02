class LoginCode < ActiveRecord::Base
  validates :code, :uniqueness => true
   
  belongs_to :user
  
  # delete all codes older than 30 days
  def self.cleanup
    LoginCode.destroy_all(["created_at < ?", Time.zone.now - 30.days])
    #LoginCode.where(["created_at < ?", Time.zone.now - 30.days]).destroy_all
  end
    
end
