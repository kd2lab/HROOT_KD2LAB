#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  rescue_from(ActiveRecord::RecordNotFound) {
    redirect_to root_url, :alert => "Für diesen Bereich ist ein Login erforderlich. "
  }
  
  rescue_from Exception do |exception|
    redirect_to root_url, :alert => "Leider ist ein interner Fehler aufgetreten. Das hroot-Entwickler-Team wurde automatisch benachrichtigt. Sollte das Problem weiterhin bestehen, wenden Sie sich bitte an das Forschungslabor."
  end
    
  rescue_from CanCan::AccessDenied do |exception|
    #flash[:error] = exception.message
    redirect_to root_url, :alert => "Für diesen Bereich ist ein Login erforderlich. "
  end
  
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from ActionController::UnknownController, with: :render_404
  
  def after_sign_in_path_for(resource)
    if current_user.user?
      account_url
    else
      dashboard_url
    end
  end

  before_filter :redirect_imported_users
  
  def redirect_imported_users
    if current_user
      if current_user.imported && !current_user.activated_after_import
        email = current_user.email
        sign_out current_user
        redirect_to activate_url(:email_insert => email),:notice => "Ihr bestehender Zugang wurde im neuen System noch nicht aktiviert.", 
      end
    end
  end
  
  def render_404
    redirect_to root_url, :alert => "Die von Ihnen aufgerufene Url ist nicht gültig."
  end
end
