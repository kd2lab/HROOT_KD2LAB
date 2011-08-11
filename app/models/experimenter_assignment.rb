class ExperimenterAssignment < ActiveRecord::Base
  ROLES = %w[experiment_admin experiment_helper]
  
  belongs_to :user
  belongs_to :experiment
end
