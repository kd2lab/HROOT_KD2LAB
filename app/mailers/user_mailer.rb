#encoding: utf-8

class UserMailer < ActionMailer::Base
  default from: "hroot@ingmar.net"
  
  def log_mail(subject, text)
    mail(:to => "ingmar.baetge@googlemail.com", :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
  
  def email(subject, text, to, from = nil)
    mail(:from => unless from.blank? then from else UserMailer.default[:from] end, :to => "mail@ingmar.net", :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
    
  def secondary_email_confirmation(user)
    @user = user
    mail(:to => user.secondary_email, :subject => "Bestätigung der alternativen E-Mail-Adresse")
  end    
  
  def change_email_confirmation(user)
    @user = user
    mail(:to => user.change_email, :subject => "Bestätigung der neuen E-Mail-Adresse")
  end    
  
  def import_email_confirmation(user)
    @user = user
    #mail(:to => user.import_email, :subject => "hroot-Anmeldung: Bestätigung der neuen E-Mail-Adresse")
    mail(:to => 'mail@ingmar.net', :subject => "hroot-Anmeldung: Bestätigung der neuen E-Mail-Adresse")
  end  
  
end
