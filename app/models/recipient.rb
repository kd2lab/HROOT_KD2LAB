class Recipient < ActiveRecord::Base
  belongs_to :message
  belongs_to :user
  
  def self.insert_bulk message, ids
    sql = "INSERT INTO recipients VALUES "+ids.collect{|id| "(NULL, #{message.id}, #{id}, NULL, NOW(), NOW())"}.join(', ')  
    ActiveRecord::Base.connection.execute(sql)
  end
end
