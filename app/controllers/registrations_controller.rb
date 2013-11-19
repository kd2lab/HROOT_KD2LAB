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
    super
  end

  def update
    super
  end
end