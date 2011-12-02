# encoding:utf-8

require 'icalendar'
require 'date'

include Icalendar

class HomeController < ApplicationController
  def index
    
  end
  
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
     
    # import admins
    @report << "--------- ADMINS ------------"
    db[:or_admin].each do |row|
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :password => "tester",
        :password_confirmation => "tester",
        :matrikel => "admin",
        :role => if (row[:admin_type] == 'admin' || row[:admin_type] == 'developer') then "admin" else "experimenter" end
      )
      u.skip_confirmation!
      u.save
           
      if !u.valid?
        @report << u.email+" "+u.errors.inspect
      end
    end
         
    # import users
    @report << "--------- USERS ------------"
    db[:or_participants].each do |row|
      field_of_studies = db[:or_lang].first(:content_type => "field_of_studies", :content_name => row[:field_of_studies])
      unless field_of_studies[:de] == '-'
        study_id = Study.find_or_create_by_name(field_of_studies[:de]).id
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
        :gender => row[:gender] == '?'? '' : row[:gender],
        :phone => row[:phone_number],
        :password => 'tester',
        :password_confirmation => "tester",
        :role => 'user',
        :begin_month => m,
        :begin_year => y,
        :deleted => row[:deleted] == 'y',
        :study_id => study_id
      )
      
      u.skip_confirmation!
      u.save
      
      # set correct creation date
      u.created_at = Date.new(1970,1,1)+row[:creation_time].seconds
      u.save
      
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
    #u = User.new :firstname => 'Harald', :lastname => 'Wypior', :email => "harald.wypior@ovgu.de", :role => "admin", :password => 'tester', :password_confirmation => 'tester', :matrikel => '1'
    #u.skip_confirmation!
    #u.save
    
    # import experiments
    @report << "--------- EXPERIMENTS ------------"
    Session.delete_all
    Experiment.delete_all
    ExperimenterAssignment.delete_all
    Participation.delete_all
    SessionParticipation.delete_all
    Location.delete_all
    
    db[:or_experiments].each do |row|
      # load type string
      exp_class = db[:or_lang].first(:content_type => "experimentclass", :content_name => row[:experiment_class])
      
      exp_type = ExperimentType.find_or_create_by_name(exp_class[:de])
      
      e = Experiment.new(
        :name => row[:experiment_name],
        :description => row[:experiment_description],
        #:restricted => row[:access_restricted] == 'y',
        :finished => row[:experiment_finished] == 'y',
        :show_in_stats => row[:hide_in_stats] != 'y',
        :show_in_calendar => row[:hide_in_cal] != 'y'
      )
      e.experiment_type_id = exp_type.id
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
                Participation.create(
                  :experiment_id => e.id,
                  :session_id => s.id,
                  :user_id => user.id,
                  :invited_at => part[:invited] == 'y' ? Time.zone.now : nil
                )
                SessionParticipation.create(
                  :session_id => s.id,
                  :user_id => user.id,
                  :showup => part[:shownup] == 'y',
                  :noshow => session[:session_finished] =='y' && part[:registered] == 'y' && part[:shownup] == 'n',                  
                  :participated => part[:participated] == 'y'
                ) 
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
              Participation.create(
                :experiment_id => e.id,
                :session_id => nil,
                :user_id => user.id,
                :invited_at => part[:invited] == 'y' ? Time.zone.now : nil,
              )
              
            end
          end
        end 
      end
    end
  end
end
