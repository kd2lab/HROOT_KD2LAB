#encoding: utf-8

class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def log_mail(subject, text)
    mail(:to => "ingmar.baetge@googlemail.com", :subject => subject, :text => text)
  end
  
  def email(subject, text, to, from = nil)
    mail(:from => unless from.blank? then from else UserMailer.default[:from] end, :to => "hroottest@googlemail.com", :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
    
  def experimenter_message(experiment, subject, text)
    # todo diese mails später an die experimentatoren schicken
    mail(:from => UserMailer.default[:from], :to => "mail@ingmar.net", :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
  
  def secondary_email_confirmation(user)
    @user = user
    mail(:to => user.secondary_email, :subject => "Bestätigung der alternativen E-Mail-Adresse")
  end    
  
end
