#encoding: utf-8

class Experiment < ActiveRecord::Base  
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :participations
  has_many :participants, :through => :participations, :source => :user
  
  has_many :sessions, :order => "start_at"
  belongs_to :experiment_type
  
  validates_presence_of :name
  
  # search for experiments, also in experimenters
  def self.search(search='')  
    includes(:experimenter_assignments, :experimenters).where(
      '(experiments.name LIKE ? OR experiments.description LIKE ? OR users.firstname LIKE ? OR users.lastname LIKE ?)',
      "%#{search}%", "%#{search}%", "%#{search}%","%#{search}%"
    )  
  end
  
  def update_experiment_assignments ids, role
    self.experimenter_assignments.where(:role => role).destroy_all
    if ids
      if ids.kind_of?(Array)    
        ids.each do |id|
          ExperimenterAssignment.create(:experiment => self, :user_id => id, :role => role)  
        end
      else
        ExperimenterAssignment.create(:experiment => self, :user_id => ids, :role => role)  
      end
    end
  end
  
  def has_open_sessions?
    return sessions.select{ |s| s.needed + s.reserve - s.participations.count > 0}.count > 0
  end
  
  def session_time_text
    sessions
      .select{ |s| s.needed + s.reserve - s.participations.count > 0}
      .map{|s| s.start_at.strftime("%d.%m.%Y, %H:%M Uhr") }
      .join("\n")
  end
  
  # einladungstext generieren
  def invitation_text_for(user) 
    text = invitation_text.dup
    
    {
      "#firstname" => user.firstname, 
      "#lastname"  => user.lastname,
      "#sessions"  => session_time_text,
      "#link"      => user.create_code
    }.each do |k,v| text.gsub!(k,v) end
    
    text
  end
  
  def sender_email
    "mail@ingmar.net"
  end
  
  def self.send_invitations
    experiments = Experiment.where("invitation_start IS NOT NULL").all
    
    experiments.each do |experiment|
      # check, how many users have been notified in this invitation run
      messaged_count = experiment.participants.where(["participations.invited_at > ?", experiment.invitation_start]).count
      
      # hours since start, divided by length, floor of the result
      elapsed_periods = ((Time.zone.now - experiment.invitation_start) / experiment.invitation_hours.hours).floor
      
      # how many messages could have been sent until now?
      max_messages = experiment.invitation_size + elapsed_periods * experiment.invitation_size
      
      # how many messages may still be sent?
      message_count_left = max_messages - messaged_count
      
      # get up to 50 random participants
      p = experiment.participations.where(:invited_at => nil).order("rand()").includes(:user).limit([[message_count_left, 50].min, 0].max)
      
      # log this message
      log = ""
      log += "#{Time.zone.now}: Versendet seit #{experiment.invitation_start}: #{messaged_count}\n"
      log += "#{Time.zone.now}: Grenze bis zu diesem Zeitpunkt: #{max_messages}\n"
      log += "#{Time.zone.now}: Noch versendbar: #{message_count_left}\n"
      log += "#{Time.zone.now}: Versand von #{p.count} Einladungen\n"
      
      # maximal 50 Personen anschreiben, aber nur, so lange es noch Pläze gibt      
      p.each do |participation|
        u = participation.user
        log += "#{Time.zone.now}: Sende Mail an #{u.email}\n"

        if experiment.has_open_sessions?
          # UserMailer.invitation_email(u, experiment).deliver
          participation.invited_at = Time.zone.now
          participation.save
        end
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
