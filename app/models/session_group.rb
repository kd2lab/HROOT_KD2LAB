class SessionGroup < ActiveRecord::Base
  USER_IS_RANDOMIZED_TO_ONE_SESSION = 1
  USER_VISITS_ALL_SESSIONS_OF_GROUP = 2
  DEFAULT_SIGNUP_MODE = USER_IS_RANDOMIZED_TO_ONE_SESSION

  belongs_to :experiment
  has_many :sessions, :order => 'start_at', :dependent => :nullify

  def is_randomized?
  	signup_mode == USER_IS_RANDOMIZED_TO_ONE_SESSION
  end

  def to_s
  	"#{sessions.map{|s| I18n.l(s.start_at.to_date)}.join(', ')}"
  end

  def sessions_for_enrollment
    # if one of the sessions is in the past, no session is open for enrollment
    if sessions.where('start_at < NOW()').count > 0
      []
    else
      sessions.select{|s| s.space_left > 0}
    end
  end

  def has_no_participants?
    return !has_participants?
  end

  def has_participants?
    sessions.each do |session|
      if session.has_participants?
        return true
      end
    end
    return false
  end
end
