class ExperimenterAssignment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :experiment
  
  def self.right_list
    [
      [I18n.t(:right_edit),"edit"],
      [I18n.t(:right_rights),"rights"],
      [I18n.t(:right_manage_sessions), "manage_sessions"],
      [I18n.t(:right_manage_participants), "manage_participants"],
      [I18n.t(:right_manage_showups), "manage_showups"],
      [I18n.t(:right_send_session_messages), "send_session_messages"],
      [I18n.t(:right_manage_invitations), "manage_invitations"],
      [I18n.t(:right_status_mails), "status_mails"]
    ]
  end

  def self.right_list_hash
    h = Hash.new
    right_list.each do |r|
      h[r[1]] = r[0]
    end
    h
  end 
 
  def self.right_keys
    right_list.collect{|r| r[1]}
  end

  def self.update_experiment_rights experiment, privileges, ignore_id = 0
    ids_to_delete = experiment.experimenter_assignments.where(["user_id <> ?", ignore_id]).map(&:id)
    ExperimenterAssignment.delete(ids_to_delete)
    
    if privileges
      privileges.each do |row|
        next if row[:id].to_i == ignore_id.to_i
        ExperimenterAssignment.create(:experiment_id => experiment.id, :user_id => row[:id], :rights => (row[:list] || []).join(','))
      end
    end
  end

  def self.update_user_rights user, privileges
    ids_to_delete = user.experimenter_assignments.map(&:id)
    ExperimenterAssignment.delete(ids_to_delete)
    
    if privileges
      privileges.each do |row|
        ExperimenterAssignment.create(:experiment_id => row[:id], :user_id => user.id, :rights => (row[:list] || []).join(','))
      end
    end
  end
      
    
end
