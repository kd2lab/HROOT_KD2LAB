# encoding: utf-8

DB_HOST = "localhost"
DB_NAME = "datenbank"
DB_USER = "user"
DB_PASSWORD = "password"


namespace :import do
  desc 'Import users from an orsee database'
  task :users => :environment do
    require 'sequel'
    
    # connect to database to import from
    db = Sequel.connect(:adapter=>'mysql2', :host=>DB_HOST, :database=>DB_NAME, :user=>DB_USER, :password=>DB_PASSWORD)
   
        
    # import studies from orsee
    puts  "--------- importing fields of study ------------"

    studies={}
    db[:or_lang].where(:content_type => "field_of_studies").collect{|row| studies[row[:content_name]] = {:name => row[:de]} }    
    studies.each do |key, row|
      unless row[:name] == '-'
        row[:id] = row[:name]
      end
    end
    
    # import users
    error_mails = []
      
    puts  "--------- importing users ------------"
    count = 0
    
    db[:or_participants].each_with_index do |row, index|
      field_of_studies = studies[row[:field_of_studies].to_s]
      unless field_of_studies[:name] == '-'
        study_id = field_of_studies[:id]
      else
        study_id = nil
      end
      
      pw = SecureRandom.hex(16)+'_1'
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :comment => row[:remarks],
        :gender => row[:gender] == '?'? '?' : row[:gender],
        :phone => row[:phone_number],
        :password => pw,
        :password_confirmation => pw,
        :role => 'user',
        :begin_of_studies => Date.new(row[:begin_of_studies].to_i,4,1),
        :birthday => nil,
        :deleted => row[:deleted] == 'y',
        :imported => true,
        :activated_after_import => false,
        :import_token => SecureRandom.hex(16),
        :course_of_studies => study_id
      )
      

      # this line is very important, otherwise devise will send a confirmation mail
      # do not comment, you could trigger a mass mailing to all imported users!
      u.skip_confirmation!
      u.admin_update = true
      u.skip_validation_of_customfields = true
      u.save
      
      if !u.valid?
        error_mails << u.email  
        puts u.errors.inspect
        #puts u.email+" "+u.errors.inspect
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
  end
  
  desc 'Import users from an orsee database'
  task :experiments => :environment do
    require 'sequel'
    
    # connect to database to import from
    db = Sequel.connect(:adapter=>'mysql2', :host=>DB_HOST, :database=>DB_NAME, :user=>DB_USER, :password=>DB_PASSWORD)
  
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
          begin
            location_name = db[:or_lang].first(:content_name => session[:laboratory_id])[:de]
          
            l = Location.find_or_create_by_name(location_name)
          rescue
            l = nil
          end
          
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
            
            user = User.find_by_email(or_user[:email]) if or_user
        
            unless user
              puts "Participant id #{part[:participant_id]} not found in experiment #{row[:experiment_name]}"
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
          user = User.find_by_email(or_user[:email]) if or_user
          
          unless user
            puts "Participant id #{part[:participant_id]} not found in experiment #{row[:experiment_name]}"
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

  desc 'Import experimeners from an orsee database'
  task :experimenters => :environment do
    require 'sequel'
    
    # connect to database to import from
    db = Sequel.connect(:adapter=>'mysql2', :host=>DB_HOST, :database=>DB_NAME, :user=>DB_USER, :password=>DB_PASSWORD)
    
    puts  "--------- importing experimenters ------------"
    

    mapping = Hash.new
    db[:or_admin].each_with_index do |row, index|
      pw = SecureRandom.hex(16)+'_1'
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :password => "hn_9jz43",
        :password_confirmation => "hn_9jz43",
        :role => 'experimenter',
        :activated_after_import => true,
      )

      u.skip_confirmation!
      u.admin_update = true
      u.skip_validation_of_customfields = true
      if u.save
        puts "#{index} Imported "+u.email
      else
        puts "E-Mail schon vorhanden: #{u.email}"
      end
      mapping[row[:adminname]] = u
    end

    db[:or_experiments].each_with_index do |row, index|
      e = Experiment.find_by_name(row[:experiment_name])

      if e
        experimenters = []
        row[:experimenter].split(',').each do |adminname|
          if mapping[adminname]
            experimenters << mapping[adminname] 
          else
            puts "missing #{adminname}"
          end
        end

        experimenters.each do |experimenter|
          ExperimenterAssignment.create(:user_id => experimenter.id, :experiment_id => e.id, :rights => '')
        end
      end

    end
  end
end