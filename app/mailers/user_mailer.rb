#encoding: utf-8

class UserMailer < ActionMailer::Base
  # the main hroot adress is the default sender - configure in development.rb
  default :from => Rails.configuration.hroot_sender_email 
  
  def log_mail(subject, text)
    mail(:to => Rails.configuration.hroot_log_email, :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
  
  def email(subject, text, to, from = nil)
    mail(:from => unless from.blank? then from else UserMailer.default[:from] end, :to => to, :subject => subject) do |format|
      format.text { render :text => text }
    end
  end
    
  def secondary_email_confirmation(user)
    @user = user
    mail(:to => user.secondary_email, :subject => I18n.t('user_mailer.subject_secondary_email_confirmation'))
  end    
  
  def import_email_confirmation(user)
    @user = user
    mail(:to => user.import_email, :subject => I18n.t('user_mailer.subject_import_email_confirmation'))
  end  

  def import_email_activation(user)
    @user = user
    mail(:to => user.email, :subject => I18n.t('user_mailer.subject_import_email_activation'))
  end  
  
end
