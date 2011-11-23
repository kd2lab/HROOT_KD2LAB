#encoding: utf-8

class OptionsController < ApplicationController

  def index
    if params[:mail_restrictions]
      Settings.mail_restrictions = params[:mail_restrictions]
      flash[:notice] = "Die Änderungen wurden gespeichert"  
    end
    
    if params[:testnr]
      Settings.testnr = params[:testnr]
      flash[:notice] = "Die Änderungen wurden gespeichert"  
    end
    
    # set default for mail restriction array
    unless Settings.mail_restrictions
      Settings.mail_restrictions = [{"prefix" => "", "suffix" => ""}]
    end
  end

  def emails

  end

end
