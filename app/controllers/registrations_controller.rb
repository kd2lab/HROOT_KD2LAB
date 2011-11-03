class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    unless Settings.suffix.blank?
      params[:user][:email] = params[:user][:email_prefix]+"@"+params[:user][:email_suffix]
    end

    super
  end

  def update
    super
  end
end