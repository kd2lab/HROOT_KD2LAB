#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  rescue_from CanCan::AccessDenied do |exception|
    #flash[:error] = exception.message
    redirect_to root_url, :notice => "Für diesen Bereich ist eine Anmeldung erforderlich. "+exception.message.to_s
  end
end
