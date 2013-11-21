# encoding:utf-8

require 'icalendar'
require 'date'

include Icalendar

class HomeController < ApplicationController
  before_filter :redirect_on_logged_in, :only => [:index]

  def index
    render :layout => 'landing'
  end
  
  def info
    render :layout => 'info'
  end
    
  def activate
    if params[:email]
      @user = User.where(:imported => true).where(:activated_after_import => false).where(:email => params[:email]).first
      if @user
        UserMailer.import_email_activation(@user).deliver
        redirect_to activate_path, :notice => t('controllers.home.notice_mail_sent')
      else
        redirect_to activate_path, :alert => t('controllers.home.notice_invalid_email')
      end
    end
  end
  
  def confirm_alternative_email
    u = User.find_by_secondary_email_confirmation_token(params[:confirmation_token])
    if u
      u.secondary_email_confirmation_token = nil
      u.secondary_email_confirmed_at = Time.zone.now
      u.save
      if current_user
        redirect_to account_alternative_email_url, :notice => t('controllers.home.notice_alternative_email')
      else
        redirect_to root_url, :notice => t('controllers.home.notice_alternative_email')
      end
    else
      redirect_to account_url
    end      
  end
  
  def calendar
    u = User.find_by_calendar_key(params[:key])
    
    if u && (u.admin? || u.experimenter?)
      cal = Calendar.new
    
      Session.all.each do |session| 
        event = Event.new
        event.start = session.start_at.to_datetime
        event.end = session.end_at.to_datetime
        event.summary = session.experiment.name
        event.location = session.location.name if session.location
        cal.add_event(event)
      end  
    
      render :text => cal.to_ical
    else
      redirect_to root_url
    end
  end
  
  # todo later automatic capturing of translation errors
  def translations
    Settings.missing_translations = {} unless Settings.missing_translations
    
    obj = Settings.missing_translations || {}
    m = params[:missing]
    m.each do |s|
      v = s.split('.')
      ref = obj
      v.each_with_index do |val, i|
        ref[val] = {} unless ref[val]
        ref = ref[val] 
      end
    end

    Settings.missing_translations = obj
    
    
    render :json => obj
  end
  
  private
  
  def redirect_on_logged_in
    if current_user
      if current_user.admin? || current_user.experimenter?
        redirect_to dashboard_path
      else
        redirect_to account_path
      end
    end
  end
    
end
