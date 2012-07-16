# encoding:utf-8

require 'icalendar'
require 'date'

include Icalendar

class HomeController < ApplicationController
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
        redirect_to activate_path, :notice => "Es wurde Ihnen eine E-Mail mit einem Link zur Freischaltung zugesendet."
      else
        redirect_to activate_path, :alert => "Zu dieser E-Mail-Adresse gibt es keinen Account"
      end
    end
  end
  
  # todo test
  def confirm_alternative_email
    u = User.find_by_secondary_email_confirmation_token(params[:confirmation_token])
    if u
      u.secondary_email_confirmation_token = nil
      u.secondary_email_confirmed_at = Time.zone.now
      u.save
      if current_user
        redirect_to account_alternative_email_url, :notice => "Ihre alternative E-Mail-Adresse wurde bestätigt."
      else
        redirect_to root_url, :notice => "Ihre alternative E-Mail-Adresse wurde bestätigt."  
      end
    else
      redirect_to account_url
    end      
  end
  
  #todo test
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
    
end
