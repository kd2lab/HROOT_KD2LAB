#encoding: utf-8

class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def log_mail(subject, text)
    mail(:to => "ingmar.baetge@googlemail.com", :subject => subject, :text => text)
  end
  
  def experiment_message(message)
    from = if message.experiment.sender_email.blank? then UserMailer.default[:from] else message.experiment.sender_email end
    mail(:from => from, :to => "hroottest@googlemail.com", :subject => message.subject, :text => message.message)
  end
  
  def invitation_email(user, experiment)
    text = experiment.invitation_text_for(user)
    from = if experiment.sender_email.blank? then UserMailer.default[:from] else experiment.sender_email end
    mail(:to => "hroottest@googlemail.com", :subject => experiment.invitation_subject, :from => from,  :text => text)
  end
  
  def confirmation_email(user, session)
    experiment = session.experiment
    text = experiment.confirmation_text_for(user, session)
    from = if experiment.sender_email.blank? then UserMailer.default[:from] else experiment.sender_email end
    mail(:to => "hroottest@googlemail.com", :subject => experiment.confirmation_subject, :from => from, :text => text)
  end
  
  def secondary_email_confirmation(user)
    @user = user
    mail(:to => user.secondary_email, :subject => "Bestätigung der alternativen E-Mail-Adresse")
  end    
  
end
