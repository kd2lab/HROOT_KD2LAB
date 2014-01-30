#encoding: utf-8

class Experiment < ActiveRecord::Base  
  acts_as_taggable_on :tags
  
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :participations
  has_many :participants, :through => :participations, :source => :user
  has_many :session_groups 
  has_many :sessions, :order => "start_at"
  has_many :history_entries, :order => :created_at
  
  validates_presence_of :name
  
  serialize :exclude_tags, ArraySerializer.new
  serialize :exclude_experiments, ArraySerializer.new

  after_create :set_defaults
  def set_defaults
    generate_token
    save
  end
  
  # search for experiments, also in experimenters
  def self.search(search='')  
    includes(:experimenter_assignments, :experimenters).where(
      '(experiments.name LIKE ? OR experiments.description LIKE ? OR users.firstname LIKE ? OR users.lastname LIKE ?)',
      "%#{search}%", "%#{search}%", "%#{search}%","%#{search}%"
    )  
  end
  
  def has_open_sessions?
    space_left > 0
  end
  
  def space_left
    sessions.in_the_future.map { |s| s.space_left }.sum
  end
    
  def open_sessions
    sessions.in_the_future.order('start_at').select{ |s| s.space_left > 0}
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
      .where('users.confirmed_at IS NOT NULL')
      .where('users.deleted=false')
      .limit([count_remaining_messages, 50].min)
      .all
  end
  
  # count users who...
  # ... are not registered in a session
  # ... have not been invited
  # ... have confirmed their account
  def uninvited_participants_count
    participants
        .where("participations.invited_at IS NULL")
        .where(" (SELECT count(sp.id) FROM session_participations sp, sessions s WHERE sp.session_id = s.id AND s.experiment_id = participations.experiment_id AND sp.user_id = users.id) = 0")
        .where('users.confirmed_at IS NOT NULL')
        .where('users.deleted=false')
        .count  
  end
  
  # selected users, who have no session participation
  def remove_participations(user_ids)
    # alle ids selectieren, die nicht in einer session eingetragen sind
    
    sql = <<EOSQL
      SELECT participations.user_id
      FROM participations WHERE
        participations.experiment_id=#{id} AND 
        participations.user_id IN (#{user_ids.map(&:to_i).join(',')}) AND
        (
          SELECT count(sessions.id) 
          FROM sessions, session_participations 
          WHERE 
            sessions.experiment_id = participations.experiment_id AND
            sessions.id = session_participations.session_id AND 
            session_participations.user_id = participations.user_id
        ) = 0;
EOSQL

    # store ids to enable history
    ids_to_delete = ActiveRecord::Base.connection.execute(sql).collect{ |res| res[0] }
    
    # if there are users, who can be removed, since they are not part of a session
    if ids_to_delete.length > 0
      # delete participation entries
      ActiveRecord::Base.connection.execute("DELETE FROM participations WHERE user_id IN (#{ids_to_delete.join(',')}) AND experiment_id=#{id}")
    end

    ids_to_delete
  end

  def excluded_ids
    # first, all direct experiment exclusions
    ids = exclude_experiments.map(&:to_i)    
    
    # second, for each excluded tag load all experiment ids
    exclude_tags.each do |tag|
      experiment_ids_for_tag = Experiment.tagged_with(tag).map(&:id)
      ids += experiment_ids_for_tag
    end
    
    # return ids
    ids
  end
  
  def generate_token
    begin
      self[:refkey] = SecureRandom.urlsafe_base64 10
    end while Experiment.exists?(:refkey => self[:refkey])
  end
  
  def sender_email_or_default
    if sender_email.blank?
      Rails.configuration.hroot_sender_email 
    else
      sender_email
    end
  end
end
