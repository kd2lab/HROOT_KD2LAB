# encoding: utf-8

class ActivationController < ApplicationController
  before_filter :load_user
  
  def index
    # a user may enter a passwort if ...
    # a) there are no mail restrictions OR
    # b) an email token was provided showing that the field import contains a valid new email adress OR
    # c) the old email is consistent with the new restrictions
    
    
    if Rails.configuration.respond_to?(:email_restriction) && !(@activation_user.email =~ Rails.configuration.email_restriction[:regex])
      # this users email is not ok with current restrictions

      # has he provided a new address?
      unless !params[:email_token].blank? && params[:email_token] == @activation_user.import_email_confirmation_token
        # if not, send him to email page
        redirect_to :action => :email
        return
      end  
    end
        
    # if we get here, we can use the password
    if params[:user]
      
      if @activation_user.update_attributes(params[:user])
        @activation_user.activated_after_import = true
        @activation_user.import_token = nil
        
        if !params[:email_token].blank? && params[:email_token] == @activation_user.import_email_confirmation_token
          @activation_user.secondary_email = @activation_user.email
          @activation_user.secondary_email_confirmed_at = Time.zone.now
          @activation_user.email = @activation_user.import_email
          @activation_user.import_email = nil
          @activation_user.import_email_confirmation_token = nil
        end  
        
        @activation_user.save
        sign_in @activation_user
        redirect_to :controller => 'account', :action => 'index'
      end
    end
  end
  
  def email
    if params[:user] 
      if Rails.configuration.respond_to?(:email_restriction) && (params[:user][:email]=~ Rails.configuration.email_restriction[:regex])
        new_email = params[:user][:email]
        
        unless User.find_by_email (new_email)
          @activation_user.update_attribute(:import_email, new_email)
          @activation_user.update_attribute(:import_email_confirmation_token, SecureRandom.hex(16))
          UserMailer.import_email_confirmation(@activation_user).deliver
          redirect_to({:action => :email_delivered}, :notice => t('controllers.activation.notice_email_sent'))
          return
        end
      end
      
      # error message otherwise
      flash.now[:alert] = t('controllers.activation.notice_invalid_email')
    end  
  end
  
  def email_delivered
    
  end
  
protected

  def load_user
    @activation_user = User.find_by_import_token(params['import_token'])
    redirect_to root_url unless @activation_user
  end
end
