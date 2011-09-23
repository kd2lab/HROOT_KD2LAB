class Participation < ActiveRecord::Base
  belongs_to :user
  belongs_to :experiment, :counter_cache => true
  belongs_to :session
  
  serialize :commitments
end
