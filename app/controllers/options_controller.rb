#encoding: utf-8

class OptionsController < ApplicationController

  def index
    if params[:commit]
      
      result = []
      if params[:mail_restrictions]
        params[:mail_restrictions].each do |r|
          result << r unless r['prefix'].blank? && r['suffix'].blank?
        end
      end
          
      if result.length > 0
        Settings.mail_restrictions = result
      else
        Settings.mail_restrictions = nil
      end
      
      flash[:notice] = t('controllers.notice_saved_changes') 
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
      Settings.import_invitation_subject = params[:import_invitation_subject]
      Settings.import_invitation_text = params[:import_invitation_text]
      redirect_to options_emails_path, :notice => t('controllers.notice_saved_changes')
    end
  end
  
  def texts
    Settings.terms_and_conditions = {} unless Settings.terms_and_conditions
    Settings.welcome_text = {} unless Settings.welcome_text
    Settings.credits_text = {} unless Settings.credits_text
    
    
    if params[:terms_and_conditions]
      Settings.terms_and_conditions = params[:terms_and_conditions]
      Settings.welcome_text = params[:welcome_text]
      Settings.credits_text = params[:credits_text]
      
      redirect_to options_texts_path, :notice => t('controllers.notice_saved_changes')
    end  
  end

end
