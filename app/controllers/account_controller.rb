# encoding: utf-8

class AccountController < ApplicationController
  authorize_resource :class => false
    
  def index
  
  end
  
  def alternative_email    
    if params[:delete]
      current_user.secondary_email = nil
      current_user.secondary_email_confirmation_token = nil
      current_user.secondary_email_confirmed_at = nil
      current_user.save
      redirect_to({:action => :alternative_email}, :notice => "Ihre alternative E-Mail-Adresse wurde gelöscht")
    end  

    if params[:resend] && !current_user.secondary_email_confirmation_token.blank?
      UserMailer.secondary_email_confirmation(current_user).deliver
      redirect_to({:action => :alternative_email}, :notice => "Die E-Mail zur Bestätigung Ihrer alternativen E-Mail-Adresse wurde Ihnen erneut zugesendet.")
    end  
      
    if params[:user]
      current_user.secondary_email = params[:user][:secondary_email]
      
      if current_user.valid?
        current_user.secondary_email_confirmation_token = SecureRandom.hex(16)
        current_user.secondary_email_confirmed_at = nil
        current_user.save
        UserMailer.secondary_email_confirmation(current_user).deliver
      end
    end
  end
  
  def email    
    if params[:delete]
      current_user.change_email = nil
      current_user.change_email_confirmation_token = nil
      current_user.save
      redirect_to({:action => :email}, :notice => "Ihre E-Mail-Änderung wurde abgebrochen.")
    end  

    if params[:resend] && !current_user.change_email_confirmation_token.blank?
      UserMailer.change_email_confirmation(current_user).deliver
      redirect_to({:action => :email}, :notice => "Die E-Mail zur Bestätigung Ihrer neuen E-Mail-Adresse wurde Ihnen erneut zugesendet.")
    end  
      
    if params[:user]
      current_user.change_email = params[:user][:change_email]
      
      if current_user.valid?
        current_user.change_email_confirmation_token = SecureRandom.hex(16)
        current_user.save
        UserMailer.change_email_confirmation(current_user).deliver      
      end
    end
  end
  
end
