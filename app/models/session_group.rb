class SessionGroup < ActiveRecord::Base
  USER_VISITS_ONE_SESSION_OF_GROUP = 1
  USER_VISITS_ALL_SESSIONS_OF_GROUP = 2
  USER_IS_RANDOMIZED_TO_ONE_SESSION = 3

  belongs_to :experiment
  has_many :sessions, :dependent => :nullify

end
