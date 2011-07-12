class UserMailer < ActionMailer::Base
  default :from => "test@hroot.net"
  
  def password_reset_instructions(user)
    @user = user
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    mail(:to => user.email, :subject => "Password Reset Instructions")
  end
  
  def activation(user)
    @user = user
    @activation_url = activate_url(user.perishable_token)
    mail(:to => user.email, :subject => "Welcome to Hroot")
  end
end
