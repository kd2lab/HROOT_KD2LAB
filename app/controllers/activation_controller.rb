# encoding: utf-8

class ActivationController < ApplicationController
  before_filter :load_user
  
  def index
    # a user may enter a passwort if ...
    # a) there are no mail restrictions OR
    # b) an email token was provided showing that the field import contains a valid new email adress OR
    # c) the old email is consistent with the new restrictions
    
    prefix, suffix = @activation_user.email.split '@'
    unless (!Settings.mail_restrictions || 
        (!params[:email_token].blank? && params[:email_token] == @activation_user.import_email_confirmation_token) ||
        User.check_email(prefix, suffix))
      redirect_to :action => :email
      return
    end
    
    # if we get here, we can use the password
    if params[:user]
      @activation_user.password = params[:user][:password]
      @activation_user.password_confirmation = params[:user][:password_confirmation]
      
      if @activation_user.save
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
      if !params[:user][:email_prefix].blank? && !params[:user][:email_suffix].blank? && User.check_email(params[:user][:email_prefix], params[:user][:email_suffix])
        new_email = params[:user][:email_prefix]+'@'+params[:user][:email_suffix]
        unless User.find_by_email (new_email)
          @activation_user.import_email = new_email
          @activation_user.import_email_confirmation_token = SecureRandom.hex(16)
          @activation_user.save
          UserMailer.import_email_confirmation(@activation_user).deliver
          redirect_to :action => :email_delivered
        end
      end
      
      # in all other cases display error
      flash[:alert] = "Diese E-Mail-Adresse ist nicht gültig."
    end
  end
  
  def email_delivered
    
  end
  
protected

  def load_user
    @activation_user = User.find_by_import_token(params['import_token'])
    redirect_to root_url, :alert => "Ungültige Url" unless @activation_user
  end
end
