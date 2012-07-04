#encoding: utf-8

class UserMailer < ActionMailer::Base
  default from: "experiments@wiso.uni-hamburg.de"
  
  def log_mail(subject, text)
    mail(:to => "ingmar.baetge@googlemail.com", :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
  
  def email(subject, text, to, from = nil)
    #todo eigentlicher empfänger raus!
    mail(:from => unless from.blank? then from else UserMailer.default[:from] end, :to => "hroottest@googlemail.com", :subject => subject+" (eigentlicher Empfänger #{to})") do |format|
      format.text { render :text => text }
    end
  end
    
  def secondary_email_confirmation(user)
    @user = user
    mail(:from => UserMailer.default[:from], :to => user.secondary_email, :subject => "Bestätigung der alternativen E-Mail-Adresse")
  end    
  
  def import_email_confirmation(user)
    @user = user
    #todo eigentlicher empfänger raus!
    #mail(:to => user.import_email, :subject => "hroot-Anmeldung: Bestätigung der neuen E-Mail-Adresse")
    mail(:from => UserMailer.default[:from], :to => 'hroottest@googlemail.com', :subject => "hroot-Anmeldung: Bestätigung der neuen E-Mail-Adresse (eigentlicher Empfänger #{user.import_email})")
  end  

  #def change_email_confirmation(user)
  #  @user = user
  #  mail(:to => user.change_email, :subject => "Bestätigung der neuen E-Mail-Adresse")
  #end    
  
  
end
