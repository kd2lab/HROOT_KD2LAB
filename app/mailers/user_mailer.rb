class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def welcome_email
    mail(:to => "mail@ingmar.net", :subject => "Hello")
  end
  
  def log_mail(subject, text)
    @text = text
    mail(:to => "mail@ingmar.net", :subject => subject, :text => text)
  end
  
  def invitation_email(user, experiment)
    @text = experiment.invitation_text_for(user)
    from = if experiment.sender_email.blank? then default[:from] else experiment.sender_email end
    mail(:to => "mail@ingmar.net", :subject => experiment.invitation_subject, :from => from)
  end
end
