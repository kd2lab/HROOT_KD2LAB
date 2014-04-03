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
    if current_user.valid_password?(params[:user][:current_password])
      current_user.skip_validation_of_customfields = true
      if current_user.update_attributes(params[:user])
        sign_in(current_user, :bypass => true)
        redirect_to edit_user_registration_path, :notice => I18n.t('devise.registrations.user.updated')
      else
        render 'devise/registrations/edit'
      end
    else
      redirect_to edit_user_registration_path, :alert => I18n.t('devise.registrations.edit.please_confirm_password')
    end
  end
end