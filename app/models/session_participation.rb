class SessionParticipation < ActiveRecord::Base
  belongs_to :user
  belongs_to :session, :counter_cache => true
end
