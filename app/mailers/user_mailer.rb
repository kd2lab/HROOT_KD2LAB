class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def welcome_email
    mail(:to => "mail@ingmar.net", :subject => "Testmail Cron")
  end
end
