class OptionsController < ApplicationController
  def index
    if params[:mail_restrictions]
      Settings.mail_restrictions = params[:mail_restrictions]
    end
    
    if params[:testnr]
      Settings.testnr = params[:testnr]
    end
      
  end

  def emails
  end

end
