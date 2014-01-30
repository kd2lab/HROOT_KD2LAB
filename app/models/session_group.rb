class SessionGroup < ActiveRecord::Base
  attr_accessible :signup_mode

  has_many :sessions
end
