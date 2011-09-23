#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :redirect_to_https
  
  def redirect_to_https
    redirect_to :protocol => "https" unless (request.ssl? || request.local?)
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    #flash[:error] = exception.message
    redirect_to root_url, :alert => "Für diesen Bereich ist eine Anmeldung erforderlich. "
  end
  
  def after_sign_in_path_for(resource)
    account_url
  end
end
