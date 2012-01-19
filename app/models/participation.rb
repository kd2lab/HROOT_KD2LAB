class Participation < ActiveRecord::Base
  belongs_to :user
  belongs_to :experiment
  belongs_to :session
end
