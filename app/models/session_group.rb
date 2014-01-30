class SessionGroup < ActiveRecord::Base
  attr_accessible :signup_mode
  belongs :experiment
  has_many :sessions
end
