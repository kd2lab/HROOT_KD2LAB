class SessionGroup < ActiveRecord::Base
  USER_IS_RANDOMIZED_TO_ONE_SESSION = 1
  USER_VISITS_ALL_SESSIONS_OF_GROUP = 2
  
  belongs_to :experiment
  has_many :sessions, :dependent => :nullify

  def is_randomized?
  	signup_mode == USER_IS_RANDOMIZED_TO_ONE_SESSION
  end

end
