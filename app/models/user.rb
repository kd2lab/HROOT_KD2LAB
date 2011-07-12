class User < ActiveRecord::Base
  acts_as_authentic

  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.password_reset_instructions(self).deliver
  end
  
  def deliver_activation_instructions!
    reset_perishable_token!
    UserMailer.activation(self).deliver
  end
  
  def activate!
    self.active = true
    reset_perishable_token!
    save
  end
  
end
