class Experiment < ActiveRecord::Base
  has_many :experimenter_assignments
  has_many :experimenters, :through => :experimenter_assignments, :source => :user
  
  validates_presence_of :name, :public_name
  
  
  def self.search(search)  
    if search  
      where('(name LIKE ? OR public_name LIKE ?)', "%#{search}%", "%#{search}%")  
    else  
      scoped  
    end  
  end
end
