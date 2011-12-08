#encoding: utf-8

class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def welcome_email
    mail(:to => "ingmar.baetge@googlemail.com", :subject => "Hello")
  end
  
  def log_mail(subject, text)
    @text = text
    mail(:to => "ingmar.baetge@googlemail.com", :subject => subject, :text => text)
  end
  
  def invitation_email(user, experiment)
    @text = experiment.invitation_text_for(user)
    from = if experiment.sender_email.blank? then UserMailer.default[:from] else experiment.sender_email end
    mail(:to => "ingmar.baetge@googlemail.com", :subject => experiment.invitation_subject, :from => from)
  end
  
  def confirmation_email(user, session)
    experiment = session.experiment
    @text = experiment.confirmation_text_for(user, session)
    from = if experiment.sender_email.blank? then UserMailer.default[:from] else experiment.sender_email end
    mail(:to => "ingmar.baetge@googlemail.com", :subject => experiment.confirmation_subject, :from => from)
  end
  
  def secondary_email_confirmation(user)
    @user = user
    mail(:to => user.secondary_email, :subject => "Bestätigung der alternativen E-Mail-Adresse")
  end    
  
end
