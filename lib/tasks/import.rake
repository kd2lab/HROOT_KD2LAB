# encoding: utf-8
namespace :import do
  desc 'Import a user csv file'
  task :all => :environment do
    require 'sequel'
    
    # connect to database to import from
    db = Sequel.connect(:adapter=>'mysql2', :host=>'localhost', :database=>'controlling_orsee', :user=>'root', :password=>'abc8765')
   
        
    # import studies from orsee
    puts  "--------- importing fields of study ------------"

    studies={}
    db[:or_lang].where(:content_type => "field_of_studies").collect{|row| studies[row[:content_name]] = {:name => row[:de]} }    
    studies.each do |key, row|
      unless row[:name] == '-'
        row[:id] = Study.find_or_create_by_name(row[:name]).id
      end
    end
    
    # import users
    error_mails = []
      
    puts  "--------- importing users ------------"
    count = 0
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
      
      pw = SecureRandom.hex(16)+'_1'
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :matrikel => if row[:matrikelnummer].blank? then "0" else row[:matrikelnummer] end,
        :gender => row[:gender] == '?'? '?' : row[:gender],
        :phone => row[:phone_number],
        :password => pw,
        :password_confirmation => pw,
        :role => 'user',
        :begin_month => m,
        :begin_year => y,
        :birthday => nil,
        :deleted => row[:deleted] == 'y',
        :imported => true,
        :activated_after_import => false,
        :import_token => SecureRandom.hex(16),
        :study_id => study_id
      )
      
      u.admin_update = true

      # this line is very important, otherwise devise will send a confirmation mail
      # do not comment, you could trigger a mass mailing to all imported users!
      u.skip_confirmation!
      u.save
      
      if !u.valid?
        error_mails << u.email  
        puts u.email+" "+u.errors.inspect
      else
        # set correct creation date (timestamp in orsee)
        u.created_at = Date.new(1970,1,1)+row[:creation_time].seconds
        u.save
        count += 1
        puts "#{count}: Imported "+u.email
      end
    end
    
    puts "----------------The following accounts could not be imported:-----------"
    
    error_mails.each do |mail|
      puts mail
    end
  
    # import experiments
    puts "--------- importing EXPERIMENTS ------------"
    
    count = 1
    db[:or_experiments].each do |row|
      print "#{count}: Importing #{row[:experiment_name]}"
      
      # load type string
      exp_class = db[:or_lang].first(:content_type => "experimentclass", :content_name => row[:experiment_class])
        
      e = Experiment.new(
        :name => row[:experiment_name],
        :description => row[:experiment_description],
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
        puts e.name.to_s+" "+e.errors.inspect
      else
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
                
                sp.save(:validate => false)
              end
            end
          end
          
          print '.'
        end 
        
        # import session independent participations
        db[:or_participate_at].filter(:experiment_id => row[:experiment_id], :session_id => 0).each do |part|
          or_user = db[:or_participants].first(:participant_id => part[:participant_id])
          user = User.find_by_email(or_user[:email])
          
          unless user
            puts or_user[:email]+" not found"
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
        
        print "\n"
        count += 1 
      end
    end
    
    # update noshow calculation
    User.update_noshow_calculation
    
  end
end