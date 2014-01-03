#encoding: utf-8

class OptionsController < ApplicationController
  authorize_resource :class => false
  
  def index
    if params[:commit]
      Settings.default_privileges = params[:default_privileges]
      redirect_to options_path, :notice => t('controllers.notice_saved_changes')
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

  def duplicates
    sql = <<EOSQL
      SELECT u.id
FROM `users` u, (
  SELECT uc.firstname, uc.lastname, uc.deleted
  FROM users uc 
  WHERE uc.deleted=0
  GROUP BY uc.firstname, uc.lastname 
  HAVING count(*) > 1
) u2
WHERE 
  u.firstname = u2.firstname
  AND u.lastname = u2.lastname
  AND u.deleted = 0 AND u2.deleted=0

EOSQL
      
    result = ActiveRecord::Base.connection.execute(sql)

    ids = result.collect{ |res| res[0] }

    params[:search] = {:fulltext => ''}
    @users = User.where(id: ids).order('lastname ASC, firstname ASC')
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
