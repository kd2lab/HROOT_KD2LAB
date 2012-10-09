# encoding: utf-8

class AccountController < ApplicationController
  authorize_resource :class => false
    
  def index
  
  end
  
  def phone
    if params[:phone]
      current_user.phone = params[:phone]
      current_user.save
      redirect_to({:action => 'phone'}, :notice => t('controllers.account.notice_phone'))
    end  
  end
  
  def alternative_email    
    if params[:delete]
      current_user.secondary_email = nil
      current_user.secondary_email_confirmation_token = nil
      current_user.secondary_email_confirmed_at = nil
      current_user.save
      redirect_to({:action => :alternative_email}, :notice =>  t('controllers.account.notice_alternative_mail1'))
    end  

    if params[:resend] && !current_user.secondary_email_confirmation_token.blank?
      UserMailer.secondary_email_confirmation(current_user).deliver
      redirect_to({:action => :alternative_email}, :notice => t('controllers.account.notice_alternative_mail2'))
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
  
  # todo secure this
  def edit
    redirect_to(account_path, :notice => t('controllers.account.notice_all_data')) unless current_user.is_missing_data?
    
    if params[:user]
      params[:user][:country_name] = nil if params[:user][:country_name] == ''
      
      if current_user.update_attributes(params[:user])
        redirect_to(account_edit_path, :notice => t('controllers.account.notice_data_changed')) 
      end
    end
  end
  
end
