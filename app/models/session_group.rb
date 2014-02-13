class SessionGroup < ActiveRecord::Base
  belongs_to :experiment
  has_many :sessions

end
