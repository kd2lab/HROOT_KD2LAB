class UserMailer < ActionMailer::Base
  default :from => "noreply@hroot.de"
  
  def password_reset_instructions(user)
    @user = user
    @edit_password_reset_url = edit_password_reset_url(user.perishable_token)
    mail(:to => user.email, :subject => "Neues Passwort bei hroot")
  end
  
  def activation(user)
    @user = user
    @activation_url = activate_url(user.perishable_token)
    mail(:to => user.email, :subject => "Anmeldung zu hroot")
  end
end
