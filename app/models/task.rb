#encoding: utf-8

class Task
  # todo hier weiter
  def self.send_session_reminders
    sql = <<EOSQL
    SELECT * FROM 
      sessions, experiments, session_participations
    WHERE
      sessions.experiment_id = experiments.id AND
      session_participations.session_id = sessions.id AND 
      reminded_at IS NULL AND
      NOW() > DATE_SUB(start_at, INTERVAL experiments.reminder_hours HOUR) AND
      NOW() < start_at AND
      (sessions.reminder_enabled = 1 OR experiments.reminder_enabled = 1)
    LIMIT 50
EOSQL

    SessionParticipation.find_by_sql(sql).each do |sp|
      if sp.session.reminder_enabled
        subject = sp.session.reminder_subject
        text = sp.session.reminder_text
      else
        subject = sp.session.experiment.reminder_subject
        text = sp.session.experiment.reminder_text
      end    
      
      # insert dynamic parts
      text = text.to_s.mreplace({
        "#firstname" => sp.user.firstname, 
        "#lastname"  => sp.user.lastname,
        "#session"  => sp.session.mail_string
      })
      
      # only deliver mails with subject and text
      unless text.blank? || subject.blank?      
        UserMailer.email(sp.user.main_email, sp.session.experiment, subject, text).deliver
        sp.reminded_at = Time.zone.now
        sp.save
      end
    end
  end
  
  # send 50 Mails from regular mail queue
  def self.process_mail_queue
    Recipient.includes(:message, :user).where('sent_at IS NULL').limit(50).each do |recipient|
      UserMailer.email(recipient.message.subject, recipient.message.message, recipient.user.main_email, recipient.message.experiment.sender_email).deliver
      recipient.sent_at = Time.zone.now
      recipient.save
    end
  end  
  
  # send invitations
  def self.send_invitations
    experiments = Experiment.where("invitation_start IS NOT NULL").all
    
    experiments.each do |experiment|
      p = experiment.load_random_participations
       
      # log this message
      log = ""
      log += "#{Time.zone.now}: Versendet seit #{experiment.invitation_start}: #{experiment.count_sent_invitation_messages}\n"
      log += "#{Time.zone.now}: Grenze bis zu diesem Zeitpunkt: #{experiment.count_max_invitation_messages_until_now}\n"
      log += "#{Time.zone.now}: Noch versendbar: #{experiment.count_remaining_messages}\n"
      log += "#{Time.zone.now}: Versand von #{p.count} Einladungen\n"
      
      # maximal 50 Personen anschreiben, aber nur, so lange es noch Plätze gibt      
      p.each do |participation|
        # ------------- possible early exits ---------------------------------
      
        # reload experiment and end loop if experiment sending is no longer active
        experiment.reload
        if experiment.invitation_start.nil?  
          break;
        end
        
        # check if there is still open space
        unless experiment.has_open_sessions?
          log += "#{Time.zone.now}: Versand beendet, keine Plätze mehr"
          break
        end
        
        # ------------- invite user -----------------------------------------
        
        # get user model in this participatoin  
        u = participation.user
        log += "#{Time.zone.now}: Sende Mail an #{u.email}\n"
        
        text = experiment.invitation_text.to_s.mreplace({
          "#firstname" => u.firstname, 
          "#lastname"  => u.lastname,
          "#sessions"  => experiment.open_sessions.map{|s| s.start_at.strftime("%d.%m.%Y, %H:%M Uhr") }.join("\n"),
          "#link"      => Rails.application.routes.url_helpers.enroll_url(u.create_code)
        })
        
        UserMailer.email(experiment.invitation_subject, text, u.main_email, experiment.sender_email).deliver        
        
        participation.invited_at = Time.zone.now
        participation.save
        
        #-------------------- only for test ------------------------------
        # todo remove this
        unless Settings.testnr.blank?
          # jeder n.te kriegt zufällig einen platz
          if rand(Settings.testnr.to_i) == 0 
            rs = experiment.sessions[rand(experiment.sessions.count)]
        
            if rs.space_left > 0
              participation.session_id = rs.id
              participation.save
              log += "#{Time.zone.now}: #{u.email} meldet sich an, freie Plätze: #{experiment.space_left-1}\n"
            end
          end
        end
        # ------------------ << only for test -----------------------------------
      end
      
      if p.count > 0
        UserMailer.log_mail("Einladungsversand für #{experiment.name}", log).deliver
      end
      
      # alle eingeladen?
      if experiment.participants.where("participations.invited_at IS NULL").count == 0
        experiment.invitation_start = nil
        experiment.save
        UserMailer.log_mail("Einladungsversand für #{experiment.name} abgeschlossen (alle Personen eingeladen)", "Es wurden alle zugeordnete Personen eingeladen.").deliver
      end
        
      # keine freien Plätze mehr?
      unless experiment.has_open_sessions?
        experiment.invitation_start = nil
        experiment.save
        UserMailer.log_mail("Einladungsversand für #{experiment.name} abgeschlossen (keine freien Plätze mehr)", "In diesem Experiment gibt es keine freien Plätze mehr").deliver
      end
      
    end
    
  end  
  
end