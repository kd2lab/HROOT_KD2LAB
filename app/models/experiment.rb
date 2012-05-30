#encoding: utf-8

class Experiment < ActiveRecord::Base  
  acts_as_taggable_on :tags
  
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :participations
  has_many :participants, :through => :participations, :source => :user
  
  has_many :sessions, :order => "start_at"
  
  validates_presence_of :name
  
  after_create :set_defaults
  def set_defaults
    auto_participation_key = SecureRandom.hex(16)
    save
  end
  
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
    space_left > 0
  end
  
  def space_left
    sessions.in_the_future.map { |s| s.space_left }.sum
  end
    
  def open_sessions
    sessions.in_the_future.select{ |s| s.space_left > 0}
  end
    
  def count_max_invitation_messages_until_now
    # hours since start, divided by length, floor of the result
    elapsed_periods = ((Time.zone.now - invitation_start) / invitation_hours.hours).floor

    # how many messages could have been sent until now?
    # (invitation_size emails maybe sent in each period of invitation_hours length)
    return invitation_size + elapsed_periods * invitation_size
  end  
      
  def count_sent_invitation_messages
    # check, how many users have been notified since the start of this invitation mailing
    # (we ignore users, which have been invited previously)
    participants.where(["participations.invited_at > ?", invitation_start]).count
  end
  
  def count_remaining_messages
    # how many messages may still be sent? Check for negative number for safety
    return [count_max_invitation_messages_until_now - count_sent_invitation_messages, 0].max
  end
  
  def load_random_participations
    if invitation_prefer_new_users
      order = "(SELECT count(sp.id) FROM session_participations sp WHERE sp.user_id = participations.user_id AND sp.participated = 1) ASC, rand()"
    else
      order = "rand()"
    end
    
    # get up to 50 random uninvited and not enrolled participants
    participations
      .where("(SELECT count(s.id) FROM session_participations sp, sessions s WHERE s.id = sp.session_id AND s.experiment_id = participations.experiment_id AND sp.user_id = participations.user_id ) = 0")
      .where(:invited_at => nil)
      .order(order)
      .includes(:user)
      .limit([count_remaining_messages, 50].min)
      .all
  end
  
  # todo remove this, make configurable
  def set_default_mail_texts
    self.confirmation_text = "Hallo,\n\nSie haben sich erfolgreich zu folgender Experiment-Session angemeldet:\n\n#session\n\nViele Grüße,\nIhr Laborteam"  
    self.invitation_text = "Hallo #firstname #lastname,\n\nwir möchten Sie gerne dazu einladen, bei einer der folgenden Experiment-Sessions teilzunehmen:\n\n#sessions\n\nSie können sich zu den Sessions mit folgedem Link anmelden:\n\n#link\n\nViele Grüße,\nIhr Laborteam"  
  end
end
