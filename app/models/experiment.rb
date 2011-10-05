#encoding: utf-8

class Experiment < ActiveRecord::Base  
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :participations
  has_many :participants, :through => :participations, :source => :user
  
  has_many :sessions
  belongs_to :experiment_type
  
  validates_presence_of :name
  
  
  def self.search(search)  
    if search  
      where(
        '(name LIKE ? OR experiments.description LIKE ? OR firstname LIKE ? OR lastname LIKE ?)',
        "%#{search}%", "%#{search}%", "%#{search}%","%#{search}%"
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
end
