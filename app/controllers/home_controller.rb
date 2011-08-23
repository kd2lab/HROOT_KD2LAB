class HomeController < ApplicationController
  def index

  end
  
  def import
    require 'sequel'
    @report = []
    
    db = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'controlling_orsee', :user=>'root', :password=>'')
   
    User.delete_all
    
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
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :matrikel => if row[:matrikelnummer].blank? then "0" else row[:matrikelnummer] end,
        :gender => row[:gender],
        :phone => row[:phone_number],
        :password => 'tester',
        :password_confirmation => "tester",
        :role => 'user'
      )
      u.skip_confirmation!
      u.save
      
      if !u.valid?
        @report << u.email+" "+u.errors.inspect
      end
    end
        
    # import experiments
    @report << "--------- EXPERIMENTS ------------"
    Session.delete_all
    Experiment.delete_all
    ExperimenterAssignment.delete_all
    ExperimentParticipation.delete_all
    Location.delete_all
    
    db[:or_experiments].each do |row|
      # load type string
      exp_type = db[:or_lang].first(:content_name => row[:experiment_class])
      
      e = Experiment.create(
        :name => row[:experiment_name],
        :description => row[:experiment_description],
        :typ => exp_type[:de],
        :restricted => row[:access_restricted] == 'y',
        :finished => row[:experiment_finished] == 'y',
        :show_in_stats => row[:hide_in_stats] != 'y',
        :show_in_calendar => row[:hide_in_cal] != 'y'
      )
      
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
            startdate = DateTime.parse(
              session[:session_start_day].to_s+"."+
              session[:session_start_month].to_s+'.'+
              session[:session_start_year].to_s+" "+
              session[:session_start_hour].to_s+":"+
              session[:session_start_minute].to_s
            )
          rescue
            startdate = nil
          end
          
          # import location of this session
          location_name = db[:or_lang].first(:content_name => session[:laboratory_id])[:de]
          
          l = Location.find_or_create_by_name(location_name)
          
          s = Session.new(
            :experiment_id => e.id,
            :description => session[:session_remarks],
            :start => startdate,
            :duration => session[:session_duration_hour]*60 + session[:session_duration_minute],
            :finished => session[:session_finished] =='y',
            :needed => session[:part_needed],
            :reserve => session[:part_reserve],
            :location => l
          )
          s.save(false)
          
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
              ExperimentParticipation.create(
                :experiment_id => e.id,
                :session_id => s.id,
                :user_id => user.id,
                :invited => part[:invited] == 'y',
                :registered => part[:registered] == 'y',
                :showup => part[:shownup] == 'y',
                :participated => part[:participated] == 'y'
              )
            end
          end
        end 
        
        # import session dependent participations
        db[:or_participate_at].filter(:experiment_id => row[:experiment_id], :session_id => 0).each do |part|
          or_user = db[:or_participants].first(:participant_id => part[:participant_id])
          user = User.find_by_email(or_user[:email])
          
          unless user
            @report << or_user[:email]+" not found"
          else
            ExperimentParticipation.create(
              :experiment_id => e.id,
              :session_id => nil,
              :user_id => user.id,
              :invited => part[:invited] == 'y',
              :registered => part[:registered] == 'y',
              :showup => part[:shownup] == 'y',
              :participated => part[:participated] == 'y'
            )
          end
        end 
      end
    end
  end
end
