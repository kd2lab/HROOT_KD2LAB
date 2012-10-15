class Message < ActiveRecord::Base
  has_many :recipients
  belongs_to :sender, :class_name => 'User'
  belongs_to :experiment
  
  def self.send_message sender_id, recipient_ids, experiment_id, subject, message, session_id = nil
    if recipient_ids.count > 0
      message = Message.create(
        :sender_id => sender_id,
        :experiment_id => experiment_id,
        :subject => subject,
        :message =>  message,
        :session_id => session_id
      )
    
      # bulk insert recipients
      sql = "INSERT INTO recipients VALUES "+recipient_ids.collect{|id| "(NULL, #{message.id}, #{id}, NULL, NOW(), NOW())"}.join(', ')  
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
