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
  
  #todo just delete :-)
  #def self.right_list_options
  #  self.right_list.collect{|r| "<option value=\"#{r.second}\">#{r.first}</option>" }.join()
  #end
  
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
