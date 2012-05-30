class Message < ActiveRecord::Base
  has_many :recipients
  belongs_to :sender, :class_name => 'User'
  belongs_to :experiment
end
