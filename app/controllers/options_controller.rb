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
    
    if params[:terms_and_conditions]
      Settings.terms_and_conditions = params[:terms_and_conditions]
      flash[:notice] = "Die Änderungen wurden gespeichert"  
    end
    
    # set default for mail restriction array
    unless Settings.mail_restrictions
      Settings.mail_restrictions = [{"prefix" => "", "suffix" => ""}]
    end
  end

  def emails
    if params[:invitation_subject]
      Settings.invitation_subject = params[:invitation_subject]
      Settings.invitation_text = params[:invitation_text]
      Settings.confirmation_subject = params[:confirmation_subject]
      Settings.confirmation_text = params[:confirmation_text]
      Settings.reminder_subject = params[:reminder_subject]
      Settings.reminder_text = params[:reminder_text]
      Settings.session_finish_subject = params[:session_finish_subject]
      Settings.session_finish_text = params[:session_finish_text]
      redirect_to options_emails_path, :notice => "Die Mailtexte wurden gespeichert"
    end
  end

end
