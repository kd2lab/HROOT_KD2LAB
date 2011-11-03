class OptionsController < ApplicationController
  def index
    if params[:suffix]
      Settings.suffix = params[:suffix]
    end
  end

  def emails
  end

end
