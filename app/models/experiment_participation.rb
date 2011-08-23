class ExperimentParticipation < ActiveRecord::Base
  belongs_to :user
  belongs_to :experiment, :counter_cache => true
  belongs_to :session
end
