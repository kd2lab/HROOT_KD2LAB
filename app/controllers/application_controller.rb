#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  rescue_from(ActiveRecord::RecordNotFound) {
    redirect_to root_url, :alert => t('controllers.application.notice_login_required')
  }
#   
#   rescue_from Exception do |exception|
#     if Rails.env.production?
#         ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
#     end
#     redirect_to root_url, :alert => t('controllers.application.error')    
#   end
#     
#   rescue_from CanCan::AccessDenied do |exception|
#     redirect_to root_url, :alert => t('controllers.application.notice_login_required')
#   end
#   
#   rescue_from ActionController::RoutingError, with: :render_404
#   rescue_from ActionController::UnknownController, with: :render_404
#   
  def after_sign_in_path_for(resource)
    if current_user.user?
      account_url
    else
      dashboard_url
    end
  end

  before_filter :redirect_imported_users
  before_filter :set_locale
 
  def set_locale
    
    cookies[:locale] = params[:locale] if params[:locale]
    #I18n.locale = params[:locale] || I18n.default_locale
    I18n.locale = cookies[:locale] || 'en'
  end
  
  def redirect_imported_users
    if current_user
      if current_user.imported && !current_user.activated_after_import
        email = current_user.email
        sign_out current_user
        redirect_to activate_url(:email_insert => email), :notice => t('controllers.application.notice_account_not_activated')
      end
    end
  end
  
  def render_404
    redirect_to root_url, :alert => t('controllers.application.notice_invalid_url')
  end
end
