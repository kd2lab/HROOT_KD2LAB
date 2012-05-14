class Message < ActiveRecord::Base
  belongs_to :recipient, :class_name => 'User'
  belongs_to :sender, :class_name => 'User'
  belongs_to :experiment
  
  def self.process_queue
    Message.order('created_at').limit(50).each do |message|
      UserMailer.experiment_message(message).deliver
      message.destroy
    end
  end  
end
