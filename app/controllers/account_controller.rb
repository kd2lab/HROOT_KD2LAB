# encoding: utf-8

class AccountController < ApplicationController
  authorize_resource :class => false
    
  def index
  
  end
  
  def options    
    if params[:delete]
      current_user.secondary_email = nil
      current_user.secondary_email_confirmation_token = nil
      current_user.secondary_email_confirmed_at = nil
      current_user.save
      redirect_to({:action => :options}, :notice => "Ihre alternative E-Mail-Adresse wurde gelöscht")
    end  

    if params[:resend]
      UserMailer.secondary_email_confirmation(current_user).deliver
      redirect_to({:action => :options}, :notice => "Die E-Mail zur Bestätigung Ihrer alternativen E-Mail-Adresse wurde Ihnen erneut zugesendet.")
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
  
  
end
