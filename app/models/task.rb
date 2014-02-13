#encoding: utf-8

class Task
  # this method is run every 5 minutes
  def self.run_tasks
    send_invitations
    process_mail_queue
    send_session_reminders
  end

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
      
      subject = replace(subject, sp.user, sp.session.experiment, sp.session)
      text = replace(text, sp.user, sp.session.experiment, sp.session)
      
      # only deliver mails with subject and text
      unless text.blank? || subject.blank?      
        UserMailer.email(subject, text, sp.user.main_email, sp.session.experiment.sender_email_or_default).deliver

        SentMail.create(
          :subject => subject,
          :message => text, 
          :from => sp.session.experiment.sender_email_or_default,
          :to => sp.user.main_email,
          :message_type => UserMailer::REMINDER,
          :user_id => sp.user.id,
          :experiment_id => sp.session.experiment_id,
          :sender_id => nil,
          :session_id => sp.session.id
        )
        
        sp.reminded_at = Time.zone.now
        sp.save
      end
    end
    Settings.last_session_reminder_task_execution = Time.now    
  end
  
  # send 50 Mails from regular mail queue
  def self.process_mail_queue
    Recipient.includes(:message, :user).where('sent_at IS NULL').limit(50).each do |recipient|
      begin
        
        # message in context of an experiment?
        if recipient.message.experiment_id
          experiment = recipient.message.experiment
        else
          experiment = nil
        end
      
        # some messages are sent in context of a session - in this case we allow some variables
        if recipient.message.session_id
          session = Session.find(recipient.message.session_id) 
        else
          session = nil
        end   

        message = replace(recipient.message.message, recipient.user, experiment, session)
        subject = replace(recipient.message.subject, recipient.user, experiment, session)
        
        # message in context of an experiment
        address = recipient.user.main_email 

        # user has valid address, email is actually sent
        if !address.blank?
          UserMailer.email(subject, message, recipient.user.main_email, recipient.message.sender.main_email).deliver

          SentMail.create(
            :subject => subject,
            :message => message, 
            :from => recipient.message.sender.main_email,
            :to => recipient.user.main_email,
            :message_type => UserMailer::REGULAR_MAIL,
            :user_id => recipient.user.id,
            :experiment_id => recipient.message.experiment_id,
            :sender_id => recipient.message.sender_id,
            :session_id => recipient.message.session_id
          )
        end  

        recipient.sent_at = Time.zone.now
        recipient.save
      rescue Exception => e
        UserMailer.log_mail("Problem sending emails", "The email with recipient id #{recipient.message.id} to \n#{recipient.user.inspect}\n can not be sent. Exception: #{e.inspect}").deliver
      end
    end
    Settings.last_process_mail_queue_task_execution = Time.now
    
  end  
  
  # send invitations
  def self.send_invitations
    experiments = Experiment.where("invitation_start IS NOT NULL").all
    
    experiments.each do |experiment|
      p = experiment.load_random_participations
       
      # log this message
      log = ""
      log += "#{Time.zone.now}: Emails sent since #{experiment.invitation_start}: #{experiment.count_sent_invitation_messages}\n"
      log += "#{Time.zone.now}: Max invitation mails (until now, count increases over time): #{experiment.count_max_invitation_messages_until_now}\n"
      log += "#{Time.zone.now}: Remaining messages to be sent (until now, count increases over time): #{experiment.count_remaining_messages}\n"
      log += "#{Time.zone.now}: Sending #{p.count} invitations\n"
      
      # while there are open seats, send up to 50 messages
      p.each do |participation|
        # ------------- possible early exits ---------------------------------
      
        # reload experiment and end loop if experiment sending is no longer active
        experiment.reload
        if experiment.invitation_start.nil?  
          break;
        end
        
        # check if there is still open space
        unless experiment.has_open_sessions?
          log += "#{Time.zone.now}: Invitation sending ended, no more open seats"
          break
        end
        
        # ------------- invite user -----------------------------------------
        
        # get user model in this participatoin  
        u = participation.user
        log += "#{Time.zone.now}: Sending mail to #{u.email}\n"
        
        link = Rails.application.routes.url_helpers.enroll_sign_in_url(u.create_code)
      
        subject = replace(experiment.invitation_subject.to_s, u, experiment, nil, link)
        text = replace(experiment.invitation_text.to_s, u, experiment, nil, link)

        if !u.main_email.blank?
          UserMailer.email(subject, text, u.main_email, experiment.sender_email_or_default).deliver        

          SentMail.create(
            :subject => subject,
            :message => text, 
            :from => experiment.sender_email_or_default,
            :to => u.main_email,
            :message_type => UserMailer::INVITATION,
            :user_id => u.id,
            :experiment_id => experiment.id,
            :sender_id => nil,
            :session_id => nil
          )
        end
        
        participation.invited_at = Time.zone.now
        participation.save
      end
      
      if p.count > 0
        UserMailer.log_mail("Invitation mailing for #{experiment.name}", log).deliver
      end
      
      # were all users invited?
      if experiment.uninvited_participants_count == 0          
        experiment.invitation_start = nil
        experiment.save
        UserMailer.log_mail("Invitation mailing for #{experiment.name} finished (reason: all users were invited)", "All assigned users were invited.").deliver
      end
        
      # no more open seats?
      unless experiment.has_open_sessions?
        experiment.invitation_start = nil
        experiment.save
        UserMailer.log_mail("Invitation mailing for #{experiment.name} finished (reason: no more open seats)", "In this experiment, all open seats are taken now, stopping invitation mailing").deliver
      end
      
    end
    
    Settings.last_invitation_task_execution = Time.now
  end  

  # helper method for text variable replacement
  def self.replace(text, user, experiment = nil, session = nil, link = nil)
    rep = [
        ["#firstname", user.firstname], 
        ["#lastname", user.lastname]
    ]

    rep << ["#activation_link", Rails.application.routes.url_helpers.activation_url(user.import_token)] if !user.import_token.blank?
    
    if experiment
      sessionlist_de = experiment.open_sessions.map{|s| s.start_at.strftime("%d.%m.%Y, %H:%M Uhr") }.join("\n")
      sessionlist_en = experiment.open_sessions.map{|s| s.start_at.strftime("%Y-%m-%d, %H:%M ") }.join("\n")
      
      rep << ["#experiment_name", experiment.name]
      rep << ["#sessionlist_de", sessionlist_de]
      rep << ["#sessionlist_en", sessionlist_en]
      rep << ["#sessionlist", sessionlist_de]
    end

    if session
      rep << ["#session_date_de", session.start_at.strftime("%d.%m.%Y")]
      rep << ["#session_date_en", session.start_at.strftime("%Y-%m-%d")]
      rep << ["#session_date", session.start_at.strftime("%d.%m.%Y")]
      rep << ["#session_start_time", session.start_at.strftime("%H:%M")]
      rep << ["#session_end_time", session.end_at.strftime("%H:%M")]
      rep << ["#session_location", if session.location then session.location.name else "" end]
    end

    if link
      rep << ["#link", link]
    end

    text.to_s.mreplace(rep)    
  end

  
  # todo later
  #def self.send_reminders_for_incomplete_sessions
    # send an email for each session
  #  Session.incomplete_sessions.each do |session|
  #    replacements = [
  #      ["#experiment_name", session.experiment.name], 
  #      ["#session_date_de", session.start_at.strftime("%d.%m.%Y")],
  #      ["#session_date_en", session.start_at.strftime("%Y-%m-%d")],
  #      ["#session_date", session.start_at.strftime("%d.%m.%Y")],
  #      ["#session_start_time", session.start_at.strftime("%H:%M")],
  #      ["#session_end_time", session.end_at.strftime("%H:%M")]
  #    ]
  #    
  #    subject = Settings.session_finish_subject.to_s.mreplace(replacements)
  #    text = Settings.session_finish_text.to_s.mreplace(replacements)
  #        
  #    # only deliver mails with subject and text
  #    unless text.blank? || subject.blank?      
  #      session.experiment.experimenter_assignments.where("rights LIKE '%status_mails%'").each do |assign|
  #        UserMailer.email(subject, text, assign.user.main_email).deliver
  #      end
  #    end
  #  end  
  #  Settings.last_incomplete_session_task_execution = Time.now
    
  #end
  
end
