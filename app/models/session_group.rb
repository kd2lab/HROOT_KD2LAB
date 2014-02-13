class SessionGroup < ActiveRecord::Base
  USER_VISITS_ALL_SESSIONS_OF_GROUP = 1
  USER_IS_RANDOMIZED_TO_ONE_SESSION = 2
  
  belongs_to :experiment
  has_many :sessions

end
