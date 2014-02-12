class SessionGroup < ActiveRecord::Base
  attr_accessible :signup_mode
  belongs_to :experiment
  has_many :sessions
end
