#encoding: utf-8

class Experiment < ActiveRecord::Base  
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :participations
  has_many :participants, :through => :participations, :source => :user
  
  has_many :sessions
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
  
  def session_mail_text
    "11.11.2011 13.00\n11.11.2011 15.00 TODO"
  end
  
  # einladungstext generieren
  def invitation_text_for(user) 
    text = invitation_text.dup
    
    {
      "#firstname" => user.firstname, 
      "#lastname"  => user.lastname,
      "#sessions"  => session_mail_text,
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
      
      
      
      p.each do |participation|
        u = participation.user
        log += "#{Time.zone.now}: Sende Mail an #{u.email}\n"

        UserMailer.invitation_email(u, experiment) #.deliver
        participation.invited_at = Time.zone.now
        participation.save
      end
      
      UserMailer.log_mail("Versand", log).deliver
      
      
    end
    
  end  
  
end
