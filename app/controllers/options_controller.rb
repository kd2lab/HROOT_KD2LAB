class OptionsController < ApplicationController
  def index
    if params[:suffix]
      Settings.suffix = params[:suffix]
    end
    
    if params[:testnr]
      Settings.testnr = params[:testnr]
    end
      
  end

  def emails
  end

end
