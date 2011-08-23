#encoding: utf-8

class Experiment < ActiveRecord::Base
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :experiment_participations
  has_many :participants, :through => :experiment_participations, :source => :user
  
  has_many :sessions
  validates_presence_of :name
  
  EXP_CLASSES = ['-', '3rd-Party-Punishment', 'Aktienmarkt', 'Alte', 'Auktionen', 'Bertrand', 'Budgetierung - Real Effort', 'Capital Budgeting  Antle/Eppen', 'Common Pool', 'Cournot', 'Diktator', 'Gift-exchange', 'Individ. (subjektives) Risiko', 'Individ. Intertemporalität', 'Individ. Unsicherheit', 'Investment', 'Koordination', 'LEN-Vertrag', 'Public Good', 'Signalspiel', 'Ultimatum', 'Verrechnungspreisverhandlung', 'Vertrauen', 'Werbemitteltest']
  
  def self.search(search)  
    if search  
      where(
        '(name LIKE ? OR experiments.description LIKE ? OR typ LIKE ? OR firstname LIKE ? OR lastname LIKE ?)',
        "%#{search}%", "%#{search}%" , "%#{search}%", "%#{search}%","%#{search}%"
      )  
    else  
      scoped  
    end  
  end
  
  def participants_search(search)  
    if search  
      where(
        '(firstname LIKE ? OR lastname LIKE ? OR email LIKE ?)',
        "%#{search}%", "%#{search}%" , "%#{search}%"
      )  
    else  
      scoped  
    end  
  end
  
  def update_experiment_assignments ids, role
    self.experimenter_assignments.where(:role => role).destroy_all
    if ids
      ids.each do |id|
        ExperimenterAssignment.create(:experiment => self, :user_id => id, :role => role)  
      end
    end
  end
    
  def sessions_finished?
    self.sessions.inject{|res, d| res && d.finished}
  end
end
