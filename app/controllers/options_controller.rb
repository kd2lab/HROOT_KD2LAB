class OptionsController < ApplicationController
  def index
    UserMailer.welcome_email(current_user).deliver
    
    if params[:suffix]
      Settings.suffix = params[:suffix]
    end
  end

  def emails
  end

end
