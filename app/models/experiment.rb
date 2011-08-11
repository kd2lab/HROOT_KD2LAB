class Experiment < ActiveRecord::Base
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  has_many :experiment_participations
  has_many :participants, :through => :experiment_participations, :source => :user
  
  has_many :sessions
  validates_presence_of :name
  
  
  def self.search(search)  
    if search  
      where('(name LIKE ? OR description LIKE ?)', "%#{search}%", "%#{search}%")  
    else  
      scoped  
    end  
  end
end
