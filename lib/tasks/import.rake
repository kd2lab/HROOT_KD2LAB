# encoding: utf-8
namespace :import do
  desc 'Import a user csv file'
  task :all => :environment do
    require 'sequel'
    
     # set a few defaults:
    Settings.invitation_subject = "Einladung zur Experiment-Session"
    Settings.invitation_text = <<EOTXT
Hallo #firstname #lastname,

an folgenden Terminen können Sie an einer Experiment-Session teilnehmen:

#sessionlist

Melden Sie sich an unter #link.

Viele Grüße,
Ihre Laborleitung
EOTXT

    Settings.confirmation_subject = "Bestätigung zur Sessionanmeldung am #session_date um #session_start_time"
    Settings.confirmation_text = <<EOTXT
Hallo #firstname #lastname,

hiermit bestätigen wir verbindlich die folgende Experiment-Teilnahme an folgenden Terminen:

#sessionlist   
EOTXT
    
    Settings.reminder_subject = "Erinnerung: Experiment-Session am #session_date um #session_end_time"
    Settings.reminder_text = <<EOTXT
Hallo #firstname #lastname,

hiermit erinnern wir Sie an die Experiment-Session am #session_date von #session_start_time bis #session_end_time.        
EOTXT

    Settings.session_finish_subject = "Sessionabschluss unvollständig: #experiment_name am #session_date um #session_start_time"
    Settings.session_finish_text = <<EOTXT
Hallo,

bitte vervollständigen Sie noch die Teilnahmedaten der folgenden Session: 
Experiment: #experiment_name
Datum: #session_date
Startzeit: #session_start_time 
EOTXT
    Settings.import_invitation_subject = "Umstellung auf hroot - Neuaktivierung Ihres bestehenden Accounts"
    Settings.import_invitation_text = <<EOTXT
Hallo #firstname #lastname,

wir haben unsere Verwaltungssoftware zur Organisation von Experimenten aktualisiert. Die neue Software heisst hroot und löst das bestehende System ab. Bitte aktivieren Sie Ihren Account und folgendem Link:

#activation_link
EOTXT

    Settings.terms_and_conditions = "Datenschutz und Nutzungsbedingungen..."
    Settings.welcome_text = "Herzlich willkomen zum internen Bereich von hroot - hier können Sie Ihre persönlichen Daten verwalten und sich zu Experimentsessions anmelden."
    
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
    puts "--------- ADMINS ------------"
    
    # create account for harald
    h = User.new :firstname => 'Harald', :birthday => "1.1.1900", :gender => 'm', :lastname => 'Wypior', :email => "harald.wypior@ovgu.de", :role => "admin", :password => 'tester_1', :password_confirmation => 'tester_1', :matrikel => '1'
    h.skip_confirmation!
    
    unless h.save
      puts h.errors.full_messages
    end

    
    db[:or_admin].each do |row|
      u = User.new(
        :email => row[:email], 
        :firstname => row[:fname],
        :lastname => row[:lname],
        :password => "tester_1",
        :password_confirmation => "tester_1",
        :matrikel => "admin",
        :birthday => "1.1.1900",
        :gender => '?',
        :role => if (row[:admin_type] == 'admin' || row[:admin_type] == 'developer') then "admin" else "experimenter" end
      )
      u.skip_confirmation!
      u.save(:validate => false)
      
      if !u.valid?
        puts u.email+" "+u.errors.inspect
      else
        puts "Imported "+u.email
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
    error_mails = []
      
    puts  "--------- USERS ------------"
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
      u.skip_confirmation!
      u.save
      
      # set correct creation date
      if !u.valid?
        error_mails << u.email  
        puts u.email+" "+u.errors.inspect
      else
        u.created_at = Date.new(1970,1,1)+row[:creation_time].seconds
        u.save
        count += 1
        puts "#{count}: Imported "+u.email
      end
    end
    
    # todo fix jans account, fix ricardos account
    j = User.find_by_email('jan.papmeier@wiso.uni-hamburg.de')
    if j
      j.role = 'admin'
      j.save
    end
    
    puts "Error emails"
    
    error_mails.each do |mail|
      puts mail
    end
  
    # import experiments
    puts "--------- EXPERIMENTS ------------"
    
    
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
    
    
    count = 1
    db[:or_experiments].each do |row|
      print "#{count}: Importing #{row[:experiment_name]}"
      
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
        puts e.name.to_s+" "+e.errors.inspect
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
              
              if u.admin? 
                assign.rights = ExperimenterAssignment.right_list.collect{|r| r.second}.join(',')
              else 
                assign.rights = ''
              end
              
              assign.save
            else
              puts "Error: "+adminname+" not found"
            end
          else
            puts "Error: "+adminname+" not found"
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