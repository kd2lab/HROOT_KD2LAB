class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def welcome_email(user)
    @user = user
    @url  = login_url
    mail(:to => "mail@ingmar.net", :subject => "Testmail")
  end
end
