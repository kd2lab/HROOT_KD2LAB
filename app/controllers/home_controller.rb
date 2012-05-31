# encoding:utf-8

require 'icalendar'
require 'date'

include Icalendar

class HomeController < ApplicationController
  def index
    render :layout => 'landing'
  end
  
  def activate
    if params[:email]
      @user = User.where(:imported => true).where(:email => params[:email]).first
      if @user
        
      else
        redirect_to activate_path, :alert => "Zu dieser E-Mail-Adresse gibt es keinen Account"
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
        redirect_to account_alternative_email_url, :notice => "Ihre alternative E-Mail-Adresse wurde bestätigt."
      else
        redirect_to root_url, :notice => "Ihre alternative E-Mail-Adresse wurde bestätigt."  
      end
    else
      redirect_to account_url
    end      
  end
  
  #def confirm_change_email
  #  u = User.find_by_change_email_confirmation_token(params[:confirmation_token])
  #  if u
  #    u.email = u.change_email
      
  #    if u.valid?
  #      u.change_email_confirmation_token = nil
  #      u.change_email = nil
  #      u.save
        
  #      if current_user
  #        redirect_to account_email_url, :notice => "Ihre E-Mail-Adresse wurde geändert."
  #      else
  #        redirect_to root_url, :notice => "Ihre E-Mail-Adresse wurde geändert."  
   #     end
  #    else
  #      redirect_to root_url, :alert => "Ihre E-Mail-Adresse konnte nicht geändert werden."  
  #    end
  #  else
  #    redirect_to account_url
  #  end      
  #end
  
  
  def calendar
    u = User.find_by_calendar_key(params[:id])
    
    if u && u.admin?
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
    
  def import
    require 'sequel'
    @report = []
    
    db = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'controlling_orsee', :user=>'root', :password=>'abc8765')
   
    User.delete_all
    Study.delete_all
    Session.delete_all
    Experiment.delete_all
    ExperimenterAssignment.delete_all
    Participation.delete_all
    SessionParticipation.delete_all
    Location.delete_all
    ActsAsTaggableOn::Tag.delete_all
    ActsAsTaggableOn::Tagging.delete_all
    Message.delete_all
    Recipient.delete_all
    Filter.delete_all
    Language.delete_all
    Degree.delete_all
    
    # import admins
    @report << "--------- ADMINS ------------"
    
    db[:or_admin].each do |row|
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :password => "tester_1",
        :password_confirmation => "tester_1",
        :matrikel => "admin",
        :birthday => '1.1.1900',
        :gender => '?',
        :role => if (row[:admin_type] == 'admin' || row[:admin_type] == 'developer') then "admin" else "experimenter" end
      )
      u.skip_confirmation!
      u.save
      
      if !u.valid?
        @report << u.email+" "+u.errors.inspect
      end
    end
        
    # prepare Study table
    studies={}
    db[:or_lang].where(:content_type => "field_of_studies").collect{|row| studies[row[:content_name]] = {:name => row[:de]} }    
    studies.each do |key, row|
      unless row[:name] == '-'
        row[:id] = Study.find_or_create_by_name(row[:name]).id
      end
    end
    
    # import users
    @report << "--------- USERS ------------"
    db[:or_participants].each do |row|
      field_of_studies = studies[row[:field_of_studies].to_s]
      unless field_of_studies[:name] == '-'
        study_id = field_of_studies[:id]
      else
        study_id = nil
      end
      
      # calculate creation date minus 6 months per semester
      start_reference =   Date.new(1970,1,1)+row[:creation_time].seconds-(6.months*(row[:begin_of_studies].to_i-1))
      m = start_reference.month
      y = start_reference.year
      
      if m>=4
        if m >= 10
          m = 10
        else
          m = 4
        end
      else
        m=10
        y = y-1
      end
      
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :matrikel => if row[:matrikelnummer].blank? then "0" else row[:matrikelnummer] end,
        :gender => row[:gender] == '?'? '?' : row[:gender],
        :phone => row[:phone_number],
        :password => 'tester_1',
        :password_confirmation => "tester_1",
        :role => 'user',
        :begin_month => m,
        :begin_year => y,
        :birthday => '1.1.1900',
        :deleted => row[:deleted] == 'y',
        :imported => true,
        :activated_after_imported => true,
        :study_id => study_id,
        :created_at => Date.new(1970,1,1)+row[:creation_time].seconds
      )
      
      u.skip_confirmation!
      u.save
      
      # set correct creation date
      #u.created_at = Date.new(1970,1,1)+row[:creation_time].seconds
      #u.save(:validate => false)
      
      if !u.valid?
        @report << u.email+" "+u.errors.inspect
      end
    end
    
    # todo fix jans account, fix ricardos account
    j = User.find_by_email('jan.papmeier@wiso.uni-hamburg.de')
    if j
      j.role = 'admin'
      j.save
    end
    
    # create account for harald
    h = User.new :firstname => 'Harald', :lastname => 'Wypior', :email => "harald.wypior@ovgu.de", :role => "admin", :password => 'tester_1', :password_confirmation => 'tester_1', :matrikel => '1'
    h.skip_confirmation!
    h.save
  
    # import experiments
    @report << "--------- EXPERIMENTS ------------"
    
    
    # create default Languages
    Language.create(:name => "Deutsch")
    Language.create(:name => "Englisch")
    Language.create(:name => "Französisch")
    Language.create(:name => "Italienisch")
    Language.create(:name => "Spanisch")
    Language.create(:name => "Chinesisch")

    # create default degrees
    Degree.create(:name => "Bachelor")
    Degree.create(:name => "Master")
    Degree.create(:name => "Diplom")
    Degree.create(:name => "Lehramt")
    Degree.create(:name => "Magister")
    
    
    
    db[:or_experiments].each do |row|
      # load type string
      exp_class = db[:or_lang].first(:content_type => "experimentclass", :content_name => row[:experiment_class])
      
      
      e = Experiment.new(
        :name => row[:experiment_name],
        :description => row[:experiment_description],
        #:restricted => row[:access_restricted] == 'y',
        :finished => row[:experiment_finished] == 'y',
        :show_in_stats => row[:hide_in_stats] != 'y',
        :show_in_calendar => row[:hide_in_cal] != 'y'
      )
      
      # only import tags with more than one letter
      if exp_class[:de].length > 1
        e.tag_list = [exp_class[:de]]
      end
  
      e.save
      
      if !e.valid?
        @report << e.name.to_s+" "+e.errors.inspect
      else
        # setup admin relation
        row[:experimenter].split(',').each do |adminname|
          admin = db[:or_admin].first(:adminname => adminname)
         
          if admin
            u = User.find_by_email(admin[:email])     
            if u      
              assign = ExperimenterAssignment.new
              assign.user = u
              assign.experiment = e
              assign.role = if u.admin? then "experiment_admin" else "experiment_helper" end
              assign.save
            else
              @report << "Error: "+adminname+" not found"
            end
          else
            @report << "Error: "+adminname+" not found"
          end  
        end
        
        # import sessions of this experiment
        db[:or_sessions].filter(:experiment_id => row[:experiment_id]).each do |session| 
          begin
            startdate = Time.zone.parse(
              session[:session_start_day].to_s+"."+
              session[:session_start_month].to_s+'.'+
              session[:session_start_year].to_s+" "+
              session[:session_start_hour].to_s+":"+
              session[:session_start_minute].to_s
            )
            duration = session[:session_duration_hour]*60 + session[:session_duration_minute]
            enddate = startdate+duration.minutes
          rescue
            startdate = nil
            enddate = nil
            duration = nil
          end
          
          # import location of this session
          location_name = db[:or_lang].first(:content_name => session[:laboratory_id])[:de]
          
          l = Location.find_or_create_by_name(location_name)
          
          s = Session.new(
            :experiment_id => e.id,
            :description => session[:session_remarks],
            :start_at => startdate,
            :end_at => enddate,
            :needed => session[:part_needed],
            :reserve => session[:part_reserve],
            :location => l
          )
          s.save(:validate => false)
          
          unless s.valid?
            puts s.errors.inspect
          end
          
          # import session dependent participations
          db[:or_participate_at].filter(:experiment_id => row[:experiment_id], :session_id => session[:session_id]).each do |part|
            or_user = db[:or_participants].first(:participant_id => part[:participant_id])
            user = User.find_by_email(or_user[:email])
        
            unless user
              @report << or_user[:email]+" not found"
            else
              # only allow onw Participation
              unless Participation.find_by_user_id_and_experiment_id(user.id, e.id)
                p = Participation.new(
                  :experiment_id => e.id,
                  :user_id => user.id,
                  :invited_at => part[:invited] == 'y' ? Time.zone.now : nil
                )
                p.save(:validate => false)
                
                sp = SessionParticipation.new(
                  :session_id => s.id,
                  :user_id => user.id,
                  :showup => part[:shownup] == 'y',
                  :noshow => session[:session_finished] =='y' && part[:registered] == 'y' && part[:shownup] == 'n',                  
                  :participated => part[:participated] == 'y'
                ) 
                
                # only build session participations with interesting information
                #if sp.showup || sp.noshow
                sp.save(:validate => false)
                #end
              end
            end
          end
        end 
        
        # import session independent participations
        db[:or_participate_at].filter(:experiment_id => row[:experiment_id], :session_id => 0).each do |part|
          or_user = db[:or_participants].first(:participant_id => part[:participant_id])
          user = User.find_by_email(or_user[:email])
          
          unless user
            @report << or_user[:email]+" not found"
          else
            unless Participation.find_by_user_id_and_experiment_id(user.id, e.id)
              p = Participation.new(
                :experiment_id => e.id,
                :user_id => user.id,
                :invited_at => part[:invited] == 'y' ? Time.zone.now : nil,
              )
              p.save(:validate => false)
              
            end
          end
        end 
      end
    end
  end
end
