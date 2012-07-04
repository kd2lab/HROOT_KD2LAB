class ExperimenterAssignment < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :experiment
  
  def self.right_list
    [
      ["Datenpflege","edit"],
      ["Rechte bearbeiten","rights"],
      ["Sessiontermine verwalten", "manage_sessions"],
      ["Zugeordnete und Sessionteilnehmer verwalten", "manage_participants"],
      ["Anwesenheit bearbeiten", "manage_showups"],
      ["Nachrichtenversand an Sessionteilnehmer", "send_session_messages"],
      ["Einladungsversand", "manage_invitations"],
      ["Statusmails", "status_mails"]
    ]
  end
  
  def self.right_list_options
    self.right_list.collect{|r| "<option value=\"#{r.second}\">#{r.first}</option>" }.join()
  end
  
  def self.update_experiment_rights experiment, rights, ignore_id = 0
    ids_to_delete = experiment.experimenter_assignments.where(["user_id <> ?", ignore_id]).map(&:id)
    ExperimenterAssignment.delete(ids_to_delete)
    
    if rights
      rights.each do |id, values|
        # experimenters may not change their own rights
        next if id.to_i == ignore_id.to_i
        ExperimenterAssignment.create(:experiment_id => experiment.id, :user_id => id, :rights => values.join(','))
      end
    end
  end
    
end
