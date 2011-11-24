#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  rescue_from CanCan::AccessDenied do |exception|
    #flash[:error] = exception.message
    redirect_to root_url, :alert => "Für diesen Bereich ist ein Login erforderlich. "
  end
  
  def after_sign_in_path_for(resource)
    if current_user.user?
      account_url
    else
      admin_url
    end
  end
end
