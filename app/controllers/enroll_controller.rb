# encoding: utf-8

class EnrollController < ApplicationController
  before_filter :load_user
  
  def index
  end

  def save
  end

protected

  def load_user
    if params['code']
      code = LoginCode.find_by_code(params['code'])
      if code && code.user
        @user = code.user
      end
    elsif current_user
      @user = current_user
    end
    
    redirect_to root_url, :alert => "Für diesen Bereich ist eine Anmeldung erforderlich. " unless @user
  end

end
