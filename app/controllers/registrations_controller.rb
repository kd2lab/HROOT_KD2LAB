#encoding: utf-8

class RegistrationsController < Devise::RegistrationsController


  # redirect user after changing the password from account pages (after login, internally, not forgot password)
  def after_update_path_for(resource)
    account_data_path(resource)
  end
        
  def index
    super
  end

  def new
    super
  end

  def create
    # if there are mail restrictions, and the user has submitted separate params for prefix and suffix..
    #if Settings.mail_restrictions && params[:user] 
    #  if User.check_email(params[:user][:email_prefix], params[:user][:email_suffix]) && !params[:user][:email_prefix].blank? && !params[:user][:email_suffix].blank?
    #    params[:user][:email] = params[:user][:email_prefix]+'@'+params[:user][:email_suffix]
    #  else
    #    params[:user][:email] = ''
    #  end
    #end         
  
    super
  end

  def update
    super
  end
end